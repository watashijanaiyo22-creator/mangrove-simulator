# Luna Max / Rendering 実装プロンプト
00/01を読み指定worktreeで実行。他者が並列作業中。担当外（特にapp/index/style/physics）を編集しない。必要なUI hookは親に仕様付きで依頼。既存GLB全体を別の木へ置換しない。

## G0/G1: 混入と波
1. renderer.draw(1)のstate、surface-memory、particles、shadow、reflection、depth、root maskのbindを追跡。BにAのtree draw/影/反射が入らないようにする。抵抗heatmapを含めroot表示の全経路でcaseIDを適用。共有rootBufferを読むだけでBに描いていないか調べる。
2. deterministic reset直後、Aのroot multiplier/forest layoutを変えてもB単独画面が同じになる試験を検証担当に依頼。camera/time/viewportを固定。A/Bの波が似ていること自体をバグにしない。
3. water surface yは必ずzb+h。独立Gerstner/FFT変位や壁時計で進む波模様は禁止。0×pauseで波/泡/粒子/濁りが停止すること。
4. 静水でfoam生成ゼロ。foamは計算された発生→速度による移流→減衰。粒子とfoamを混同しない。波の進行を最低10秒1×で記録し、5frame以上の連続画像で滑り/ちらつきを報告する。

## G2: 動的地形と土砂表示
5. 現在/初期のbed高さ選択をRenderer.showInitialBedで追加（default false）。初期/現在で同じtexture world scale、照明、cameraを使う。normalは表示対象の高さから再計算。collision/physics bufferに表示切替を書き戻さない。
6. 地形macro形状は物理zbのみ。shader noiseで侵食溝や崖を作らない。PBR微細normalは輪郭を変えない。世界座標投影で地形変化時のUV伸びを避ける。mud normalの回転blendとcolorの回転blendを一致させる。
7. 累積Eだけで地面を削れた色にしない。初期bedとの差、net depositと浸水履歴を用いて既存地盤/堆積面/濡れをblend。現在1class sedimentなのでsand/mud別質量が存在するように装わない。素材は表面表現であることを親へ報告。
8. 濁りはactual ms/max(h,dry)をray上でsample。水柱深さを超えて積分しない。海底/根の前景拒否、岸際depth fade、0濃度の透過を検証。A/B別field。
9. 土砂観察markerは流速で移流、沈降速度で下降、bed交差で消失。発生weightはactual erosion flux、再浮遊はそのstepのerosionから。markerは描画proxyでありmassを加減しない。毎frame無条件に同じx帯へ撒く方式は使わない。budget/depositionに二重計上しない。
10. P1で固定・smoke済みのroot-proxy仕様に従い同じworld segmentsから半透明cylinder overlay生成。半径倍率とraster source一致、通常meshのカード根と二重表示を避ける方針を親と確認。元leaf/trunk texture保持。
11. 根の埋没は更新地盤に対しfragment/geometryをclip。侵食時に存在しない地下根を伸ばして作らない。元meshの下端が露出したら限界を報告。
12. 木の暗部はlinear-space ambient/direct光で改善。shadowを消して明るくしない。alphaカードの輪郭、mipmap、遠景aliasを同時確認。frame毎のtexture/bindgroup再生成禁止。

## G3: 性能と受入
13. 有効/無効を別々に計測しGPU passコストを比較。reflection半解像度、pixel ratio上限、marker数の品質設定案を親へ送る。低品質でもphysics解像度/係数は変えない。
14. device lost・resize・表示切替でresourceリークしない。disposeが所有GPU資源を解放。比較offの非表示caseはrender省略、physicsは比較のため継続。
15. 自然表示、線off、数字off、tracer off、heatmap offで初期/経過後を撮影。差の可視性と写真のような質感を別評価。見分けられなければ何が隠しているか（波/透明度/照明/scale）を具体的に修正し再撮影。数値だけを成功理由にしない。
成果: commit、before/after画像と1×動画、各case独立性、pauseテスト、resource/performance結果、未達事項。

粒子発生APIと根proxyが未確定なら代替実装を推測しない。別の独立描画修正を進め、依存項目はBLOCKED-DEPENDENCYとして親に報告。自然表示の固定撮影と受入は05に従う。
