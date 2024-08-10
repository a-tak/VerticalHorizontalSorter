# -VerticalHorizontalSorter

このスクリプトはDaVinci Resolve Scripting APIを使用し縦写真と横写真をそれぞれ別のタイムラインに振り分けます。

## 制限事項

* 同じビンにJPGとDNGが配置されている必要があります
  * JPGの縦横解像度から縦横判定するのでDNGだけだと動作しません
* RAWファイルのクリップ名は拡張子部分がDNGまたはdngである必要があります
* 縦写真のDNGファイルの回転方向は固定。現在は左に90度回転するようにしている。