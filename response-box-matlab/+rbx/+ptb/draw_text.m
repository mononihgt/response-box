function draw_text(winPtr, winRect, content, color255, textSize, xPos, yPos, fontName, backgroundColor)
%DRAW_TEXT Draw Unicode text in a PTB window via a Java-rendered texture.

if nargin < 8 || strlength(string(fontName)) == 0
    fontName = "Microsoft YaHei";
end
if nargin < 9 || isempty(backgroundColor)
    backgroundColor = [0, 0, 0];
end

textValue = local_text_value(content);
imageRgb = local_render_text_image(textValue, color255, textSize, fontName, backgroundColor);
[imageHeight, imageWidth, ~] = size(imageRgb);
dstRect = local_destination_rect(winRect, imageWidth, imageHeight, xPos, yPos);

texturePtr = Screen('MakeTexture', winPtr, imageRgb);
cleanup = onCleanup(@()Screen('Close', texturePtr)); %#ok<NASGU>
Screen('DrawTexture', winPtr, texturePtr, [], dstRect);

end

function imageRgb = local_render_text_image(textValue, color255, textSize, fontName, backgroundColor)
if ~usejava('jvm')
    error('response_box:JavaUnavailable', 'MATLAB Java support is required for Unicode PTB text rendering.');
end

lines = cellstr(splitlines(string(textValue)));
if ~isempty(lines) && isempty(lines{end})
    lines(end) = [];
end
if isempty(lines)
    lines = {''};
end

fontSize = max(1, round(textSize));
fontObj = javaObject('java.awt.Font', char(fontName), 0, fontSize);

probeImage = javaObject('java.awt.image.BufferedImage', 1, 1, 1);
probeGraphics = probeImage.createGraphics();
probeGraphics.setFont(fontObj);
metrics = probeGraphics.getFontMetrics();

lineWidths = zeros(1, numel(lines));
for idx = 1:numel(lines)
    lineWidths(idx) = max(1, metrics.stringWidth(char(lines{idx})));
end
lineHeight = max(1, metrics.getHeight());
ascent = metrics.getAscent();
probeGraphics.dispose();

paddingX = max(4, round(fontSize * 0.35));
paddingY = max(4, round(fontSize * 0.25));
imageWidth = max(1, ceil(max(lineWidths) + paddingX * 2));
imageHeight = max(1, ceil(lineHeight * numel(lines) + paddingY * 2));

imageObj = javaObject('java.awt.image.BufferedImage', imageWidth, imageHeight, 1);
graphicsObj = imageObj.createGraphics();
graphicsObj.setFont(fontObj);

bg = local_rgb(backgroundColor);
fg = local_rgb(color255);
graphicsObj.setColor(javaObject('java.awt.Color', int32(bg(1)), int32(bg(2)), int32(bg(3))));
graphicsObj.fillRect(0, 0, imageWidth, imageHeight);
graphicsObj.setColor(javaObject('java.awt.Color', int32(fg(1)), int32(fg(2)), int32(fg(3))));

for idx = 1:numel(lines)
    lineText = char(lines{idx});
    drawX = round((imageWidth - lineWidths(idx)) / 2);
    drawY = round(paddingY + ascent + (idx - 1) * lineHeight);
    graphicsObj.drawString(lineText, drawX, drawY);
end
graphicsObj.dispose();

argbSigned = int32(imageObj.getRGB(0, 0, imageWidth, imageHeight, [], 0, imageWidth));
argb = typecast(argbSigned(:), 'uint32');
red = uint8(bitand(bitshift(argb, -16), 255));
green = uint8(bitand(bitshift(argb, -8), 255));
blue = uint8(bitand(argb, 255));

imageRgb = zeros(imageHeight, imageWidth, 3, 'uint8');
imageRgb(:, :, 1) = reshape(red, imageWidth, imageHeight)';
imageRgb(:, :, 2) = reshape(green, imageWidth, imageHeight)';
imageRgb(:, :, 3) = reshape(blue, imageWidth, imageHeight)';

end

function dstRect = local_destination_rect(winRect, imageWidth, imageHeight, xPos, yPos)
rect = double(winRect(:)');
[centerX, centerY] = RectCenter(rect);

if ischar(xPos) || (isstring(xPos) && isscalar(xPos) && string(xPos) == "center")
    left = round(centerX - imageWidth / 2);
elseif isnumeric(xPos) && isscalar(xPos)
    left = round(xPos);
else
    error('response_box:PTBUnsupportedXPos', 'Unsupported PTB text X position.');
end

if ischar(yPos) || (isstring(yPos) && isscalar(yPos) && string(yPos) == "center")
    top = round(centerY - imageHeight / 2);
elseif isnumeric(yPos) && isscalar(yPos)
    top = round(yPos);
else
    error('response_box:PTBUnsupportedYPos', 'Unsupported PTB text Y position.');
end

dstRect = [left, top, left + imageWidth, top + imageHeight];
end

function textValue = local_text_value(content)
if isstring(content)
    if ~isscalar(content)
        content = join(content, newline);
    end
    textValue = char(content);
elseif ischar(content)
    textValue = content;
elseif iscellstr(content)
    textValue = strjoin(content, newline);
else
    textValue = char(string(content));
end
end

function rgb = local_rgb(color255)
rgb = round(double(color255(:)'));
if numel(rgb) == 1
    rgb = repmat(rgb, 1, 3);
end
rgb = max(0, min(255, rgb(1:3)));
end
