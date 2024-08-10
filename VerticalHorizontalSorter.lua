local Con = {
    STILL = "スチル"
}

-- メディアプールから全てのメディアを取得
local resolve = Resolve()
local project = resolve:GetProjectManager():GetCurrentProject()
local mediaPool = project:GetMediaPool()
local folder = mediaPool:GetCurrentFolder()
local mediaItems = folder:GetClipList()

-- 縦の写真を格納するためのタイムラインを作成
local verticalTimeline = mediaPool:CreateEmptyTimeline("#Vertical Photos " .. os.date("%Y-%m-%d %H-%M-%S"))
-- 横の写真を格納するためのタイムラインを作成
local horizontalTimeline = mediaPool:CreateEmptyTimeline("#Horizontal Photos " .. os.date("%Y-%m-%d %H-%M-%S"))
-- メディアアイテムをループして、向きに応じてタイムラインに追加
for _, mediaItem in ipairs(mediaItems) do
    if mediaItem:GetClipProperty("Type") == Con.STILL then
        -- ビデオクリップの解像度を取得
        local resolution = mediaItem:GetClipProperty("Resolution")
        -- 解像度から画像の向きを判定
        local width, height = resolution:match("(%d+)x(%d+)")
        if tonumber(width) > tonumber(height) then
            -- 横向きの画像
            project:SetCurrentTimeline(horizontalTimeline)
            mediaPool:AppendToTimeline(mediaItem)
        else
            -- 縦向きの画像
            project:SetCurrentTimeline(verticalTimeline)
            mediaPool:AppendToTimeline(mediaItem)
        end
    end
end

