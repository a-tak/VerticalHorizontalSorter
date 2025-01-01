local Con = {
    STILL = "スチル",
    ROTATION_ANGLE = 90.0,
    ZOOM = 1.334,
    DISTORTION = 0.14,
    POWER_GRADE_PATH = [[D:\DaVinci Resolve\PowerGrade\GH7 Normalize.drx]]
}

-- メディアプールから全てのメディアを取得
local resolve = Resolve()
local project = resolve:GetProjectManager():GetCurrentProject()
local mediaPool = project:GetMediaPool()
local folder = mediaPool:GetCurrentFolder()
local mediaItems = folder:GetClipList()

-- DRXを適用する関数
local function applyGradeFromDRXUsingGraph(item, drxFilePath, gradeMode)
    if not drxFilePath then
        print("DRXファイルが指定されていません")
        return
    end

    -- ノードグラフを取得
    local graph = item:GetNodeGraph()
    if not graph then
        print("NodeGraphを取得できませんでした: " .. item:GetName())
        return
    end

    -- DRXを適用
    print("Applying DRX file to: " .. item:GetName())
    local success = graph:ApplyGradeFromDRX(drxFilePath, gradeMode)
    if not success then
        print("DRXの適用に失敗しました: " .. drxFilePath)
    end
end

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

-- 横の写真のタイムラインをクリップ名でソート
table.sort(horizontalMediaItems, function(a, b)
    return a:GetClipProperty("Clip Name") < b:GetClipProperty("Clip Name")
end)

-- 縦の写真のタイムラインをクリップ名でソート
table.sort(verticalMediaItems, function(a, b)
    return a:GetClipProperty("Clip Name") < b:GetClipProperty("Clip Name")
end)

-- DNGのmediaItemを取得してDRXを適用
project:SetCurrentTimeline(horizontalTimeline)
for _, item in ipairs(horizontalMediaItems) do
    mediaPool:AppendToTimeline(item)
    local dngItem = getMediaItemByBaseNameAndDNG(item)
    if dngItem then
        mediaPool:AppendToTimeline(dngItem)
    end
end

project:SetCurrentTimeline(verticalTimeline)
for _, item in ipairs(verticalMediaItems) do
    mediaPool:AppendToTimeline(item)
    local dngItem = getMediaItemByBaseNameAndDNG(item)
    if dngItem then
        mediaPool:AppendToTimeline(dngItem)
    end
end

-- 横写真のタイムラインのDNGの各種設定をする
local horizontalTimelineItems = horizontalTimeline:GetItemListInTrack("video",1)
if horizontalTimelineItems then
    for _, item in ipairs(horizontalTimelineItems) do
        local mediaPoolItem = item:GetMediaPoolItem()
        if mediaPoolItem:GetClipProperty("Format") == "DNG" then
            -- DNGファイルの時だけレンズ補正を設定
            item:SetProperty("Distortion", Con.DISTORTION)
            -- DRXファイルを適用
            applyGradeFromDRXUsingGraph(item, Con.POWER_GRADE_PATH, 0)
        end
    end
end

-- 縦写真のタイムラインのDNGの各種設定をする
local verticalTimelineItems = verticalTimeline:GetItemListInTrack("video",1)
if verticalTimelineItems then
    for _, item in ipairs(verticalTimelineItems) do
        local mediaPoolItem = item:GetMediaPoolItem()
        if mediaPoolItem:GetClipProperty("Format") == "DNG" then
            -- 回転方向は固定
            item:SetProperty("RotationAngle", Con.ROTATION_ANGLE)
            item:SetProperty("ZoomX", Con.ZOOM)
            -- DNGファイルの時だけレンズ補正を設定
            item:SetProperty("Distortion", Con.DISTORTION)
            -- DRXファイルを適用
            applyGradeFromDRXUsingGraph(item, Con.POWER_GRADE_PATH, 0)
        end
    end
end

-- 縦用タイムラインの解像度を設定する
-- 最初に今の縦横解像度を取得
local width = verticalTimeline:GetSetting("timelineResolutionWidth")
local height = verticalTimeline:GetSetting("timelineResolutionHeight")

-- プロジェクト設定を使わない指定
verticalTimeline:SetSetting("useCustomSettings", "1")

verticalTimeline:SetSetting("timelineResolutionWidth", height)
verticalTimeline:SetSetting("timelineResolutionHeight", width)
verticalTimeline:SetSetting("timelineOutputResolutionWidth", height)
verticalTimeline:SetSetting("timelineOutputResolutionHeight", width)
