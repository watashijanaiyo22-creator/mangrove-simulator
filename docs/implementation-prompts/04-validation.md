# Luna Max / Independent Validation プロンプト
00/01を読み、指定worktreeで作業。アプリ本体を編集しない。他者が実装中なので、最新統合commitへ移るタイミングは親の指示に従う。コードを読んだだけではruntime PASSにしない。

## 環境
まずnode、ブラウザ、WebGPUを実測。既存scriptsのPlaywrightパスを無条件に信頼しない。利用可能なインストールを探し、なければ親へ報告。ローカルポートはvalidation=4176、physics=4174、rendering=4175、統合=4173を予約。serve.mjsがport引数を受けない場合、親が共通対応してから起動。別worktreeを4173で誤検証しない。証拠JSONにcommit、workdir、URL、device、viewport、seed、config、実行コマンドを保存。wall-clock sleepだけでsimulation timeを決めない。

## G0で作る失敗再現
- B独立性: 同一初期値、同一2000step。Aのforest layout/diameterだけ変更してBの全配列がbitwise一致。A側は変化することも確認する。旧テスト「両ケースともvegetation:false」だけでは不十分。
- B描画独立性: B単独、固定camera/time/viewport、A配置のみ変更。GPUでpixel差を比較、環境差がなければ一致、差があれば影/反射/泡/root overlayを一つずつ分離。case切替順A→BとB単独起動も比較。
- 岸線符号: 合成linear slopeを0.01m下げるとshorelineは+x、上げると-x。datum crossingなし→null。波によるwet/dry移動をshoreline後退と混同しない。
- 初期C/境界C別ゼロ、堆積のみ、侵食のみ、通常条件の4実験。E/D/flux/bed volumeと岸線方向を併記し、どちらも前進=即FAILにしない。

## 回帰試験
- npm run checkおよび既存8テスト。
- CPU/GPU parity、静水、閉鎖系水/土砂保存、analytic settling、stock depletion、ドラッグ散逸。
- root field band面積、1×/1.5×/2×倍率、格子解像度比較、見た目/抵抗proxyの投影一致。
- pauseでrenderを10frames進めても物理time/state/markerが不変。reset後の全観測memoryゼロ、ケース切替で古い軌跡が残らない。
- 1×/4×/8×/最大速度を同じ物理step数で比較しstate同一。fpsから侵食量が変わらない。
- import(export(settings))で同じstep数のstate一致。不正JSON/NaN/負濃度/未知versionを拒否して既存実験を破壊しない。
- 新APIの初期/現在表示切替、camera移動、数字off、line offを行ってstate不変。

## 観察品質
初期/180s/1080sを同じカメラで撮影。natural/no numbers/no lines/no diagnostic tracer/no heatmap。全景と岸接写を両方残す。波1×10秒以上の動画、濁り輸送、泡寿命、根の埋没/露出を見る。格子artifact、根カード、テクスチャ滑り、反射混入を箇所と時刻付きで記録。減衰率や地形差を画像から推測して数値にしない。ユーザーの写真参照は美術目標、物理正解画像ではない。

## 実験マトリクス
baseline96本・diameter1、wave0/.06/.18/.30m、tide-.1/0/.2m、period6/9/12sのうちまず単変量で基準条件との差を比較。全組合せ網羅は安定性確認後。解析窓はwave到達後の整数周期、sample間隔はperiod/32以下。forest前・内部・背後でH_equiv、速度RMS、tauを測る。任意に最も都合のよい地点を選ばない。

## 性能/操作
同一M2、1440×960、左右表示、4×/8×で各60秒後に計測。別GPU負荷試験と同時実行しない。15分連続runで初期/5/10/15分のfps中央値/p95 frame time、actual speed、メモリを記録。30fpsを目標とするが未達を隠さない。機器温度を取得できなければ未測定と記す。
1280×720/390×844でpanelの末尾までスクロールでき、canvas・buttonの重なりなし。keyboard/Shift pan/reversed orbit/zoom bounds、同期カメラ、phase stop≤dt、縮尺変化をassert。

## 報告
docs/implementation-prompts/reports/validation.mdに各要件PASS/FAIL/BLOCKED、証拠path、再現手順、期待/実際を記載。FAILは所有者へ送るが自分で本体修正しない。スクリーンショットだけでphysics PASS、テストだけでnatural quality PASSにしない。

成分別許容差、固定撮影条件、証拠保全、中断再開は05を優先。テストがまだ未実装ならBLOCKEDではなくNOT-RUN。再現しなかった報告症状はNOT-REPRODUCEDとし、修正済みとは書かない。
