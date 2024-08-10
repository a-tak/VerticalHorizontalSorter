local Con = {
    STILL = "スチル",
    ROTATION_ANGLE = 90.0
}

-- メディアプールから全てのメディアを取得
local resolve = Resolve()
local project = resolve:GetProjectManager():GetCurrentProject()
local mediaPool = project:GetMediaPool()
local folder = mediaPool:GetCurrentFolder()
local mediaItems = folder:GetClipList()

-- 同じベース名で拡張がDNGのmediaItemを取得する関数
local function getMediaItemByBaseNameAndDNG(mediaItem)
    local baseName = mediaItem:GetClipProperty("Clip Name"):match("(.+)%..+$") -- ベース名を取得
    for _, item in ipairs(mediaItems) do
        local itemName = item:GetClipProperty("Clip Name")
        if itemName:match("^" .. baseName .. "%.dng$") or itemName:match("^" .. baseName .. "%.DNG$") then
            return item
        end
    end
    return nil -- 見つからなかった場合
end



-- 縦の写真を格納するためのタイムラインを作成
local verticalTimeline = mediaPool:CreateEmptyTimeline("#Vertical Photos " .. os.date("%Y-%m-%d %H-%M-%S"))
-- 横の写真を格納するためのタイムラインを作成
local horizontalTimeline = mediaPool:CreateEmptyTimeline("#Horizontal Photos " .. os.date("%Y-%m-%d %H-%M-%S"))
-- メディアアイテムをループして、向きに応じてタイムラインに追加
local horizontalMediaItems = {}
local verticalMediaItems = {}
for _, mediaItem in ipairs(mediaItems) do
    if mediaItem:GetClipProperty("Type") == Con.STILL then
        -- ビデオクリップのフォーマットを取得
        local format = mediaItem:GetClipProperty("Format")
        if format == "JPEG" then
            -- JPEGの画像の解像度を取得
            local resolution = mediaItem:GetClipProperty("Resolution")
            -- 解像度から画像の向きを判定
            local width, height = resolution:match("(%d+)x(%d+)")
            if tonumber(width) > tonumber(height) then
                -- 横向きの画像
                table.insert(horizontalMediaItems, mediaItem)
            else
                -- 縦向きの画像
                table.insert(verticalMediaItems, mediaItem)
            end
        end
    end
end

project:SetCurrentTimeline(horizontalTimeline)
for _, item in ipairs(horizontalMediaItems) do
    mediaPool:AppendToTimeline(item)
    -- DNGのmediaItemを取得して追加
    local dngItem = getMediaItemByBaseNameAndDNG(item)
    if dngItem then
        mediaPool:AppendToTimeline(dngItem)
    end
end
project:SetCurrentTimeline(verticalTimeline)
for _, item in ipairs(verticalMediaItems) do
    mediaPool:AppendToTimeline(item)
    -- DNGのmediaItemを取得して追加
    local dngItem = getMediaItemByBaseNameAndDNG(item)
    if dngItem then
        mediaPool:AppendToTimeline(dngItem)
    end
end

-- 縦写真のタイムラインのDNGの向きを変える
local verticalTimelineItems = verticalTimeline:GetItemListInTrack("video",1)
if verticalTimelineItems then
    for _,item in ipairs(verticalTimelineItems) do
        local mediaPoolItem = item:GetMediaPoolItem()
        if mediaPoolItem:GetClipProperty("Format") == "DNG" then
            -- 回転方向は固定
            item:SetProperty("RotationAngle", Con.ROTATION_ANGLE)
        end
    end
end
