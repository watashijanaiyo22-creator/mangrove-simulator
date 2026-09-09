# Luna Max / Physics 実装プロンプト
00の所有権と01の仕様に厳密に従う。あなたは単独作業ではない。他者の編集を戻さず担当外を変更しない。作業worktreeは親が指定。親への報告前に担当内だけcommitする。推測で欠落仕様を埋めず、具体的提案を親へ送る。

## G0/G1: 最優先の不具合切り分け
1. gpu.js、physics.js、scenario.js、physics.wgslを照合。現行root switchがBで0、A/B bufferが別であることをassertする。あり側のroot fieldを2倍・配置変更しても、reset後のBの全Cellが不変となるGPUテストを作る。2000stepでbitwise一致を要求。
2. 初期濃度/境界濃度を01のAPIで分離。initialStateのms=h*C。濃度ゼロでも海底の土砂在庫は維持。境界水・土砂のledgerをそのまま保持。
3. 次の実験を固定seed、同じforcingで実行: a)波0/境界off/初期C0、b)波0/境界off/初期C0.12、c)波0.18/初期C0/境界C0、d)波0.18/初期C0.12/境界C0.12。aは静止、bは沈降と等量のbed増加、c/dは岸線方向を事前に固定しない。実際のE/D/fluxで説明する。
4. CPU/GPU同じ交換式にする。sourceが土砂を作る、stockが負になる、dt拡大で顕著になる修正は拒否。CPU oracleもGPUと同じ誤りを写すだけにしない。analytic settlingとquadratic dragを独立チェック。
5. 元の8テスト維持。閉鎖系mass drift≤初期massの1e-5、静水max speed≤1e-5m/s、短期CPU/GPU誤差は05の成分別許容差を使用。補正ledgerゼロを合格条件とし、clampで失敗を隠さない。

## G2: 根の形状整合
工程6–7の抽出試作はP0で先行し、05の対応率ゲートを通す。Renderingを待たせたままP3で初めて抽出を始めない。
6. GLB低部の連結meshとalpha root cardsを調査。元meshの法線方向一律膨張は使わない（葉カードまで太るため）。中心線+半径で表現できる根のproxyを生成し、public/tree/root-proxy.jsonに{version:1,units:'m',segments:[{a:[x,y,z],b:[x,y,z],radius,sourcePart,fitError}]}を保存。座標は既存prepared meshと同じtree-local座標。
7. proxyの投影と元根の正面/側面/上面を比較。代表根のfitErrorと不足を報告。既定1×の根分布を別の生成樹で置換しない。抽出不可能な部分は勝手に補完せず、対応率を親へ送る。この工程はデータ精度ゲートであり「見た目がそれらしい」だけでは通過不可。
8. src/root-geometry.jsは純粋関数buildRootSegments(proxy,trees,diameterScale)をexport。半径のみ倍率、中心線/樹冠scaleは不変。地盤合わせはrendererの既存変換と一致。返すworld segmentsを描画とrasterの共通入力とする。
9. 抵抗は各segmentの2r*lengthを基に、実半径を考慮したXYでなくXZ footprintへ保守的に分配。4垂直bandとの交差を計算。分配後総投影面積の誤差≤1%。重複は加算、領域外切り捨て面積を記録。格子refinementで総面積1%以内。無根Bへ書かない。
10. proxy採用は親・描画担当との統合後。元カード根と新円柱根の二重抵抗・二重描画は禁止。透明proxy overlayで比較し、通常表示への置換は対応率確認後。

## G2/G3: 波と解像度
11. 同じ物理領域、dx=.6/.3m、dtも比例縮小して、無根flatbedの正弦波を比較。入口・中間・出口のetaとqを固定物理時間間隔で記録。解析の浅水波速度sqrt(gh)と到達時間を比較。森林なしの数値減衰を別表にする。
12. 根あり/なしで規則波等価波高H_equiv、流速RMS、底面せん断応力を同じ帯・同じ定常時間窓で計測。Cdを結果に合わせて調整しない。文献根拠とモデルの適用範囲を報告。
13. 反射を調べるため入射packetと反射packetの時間窓を分離。反射が観察区に戻る時刻を報告。吸収境界修正は入射forcingとledgerを維持、閉鎖系テストも維持。
14. adaptive/local refinementをいきなり追加しない。全域2解像度比較で結果とcostを報告し、必要な場合だけ親へ局所refinementのface flux conservation仕様を提出。独断で別solverを導入しない。

成果: commit、変更ファイル、テストコマンド、JSON結果、根対応率、保存則誤差、既知限界。未測定をPASSとしない。

本プロンプトの物理誤差・抽出採用・停止判断は05を優先。局所refinementは結果待ちの未完項目として追跡し、全域refinementだけで完了と書かない。
