# 実行ゲート・受入・復旧 v2

00–04と不一致なら本書を優先。親は矛盾を解消してからworkerを起動。長時間実装は無期限の試行錯誤ではなく、証拠の残る小さな統合単位で進める。

## P0: 事前検証（アプリ機能は変更しない）
親は既存テスト、起動URL、WebGPU、アセット読込、現行スクリーンショットを記録。Luna Maxは次の独立調査だけ並列可: Physicsは根抽出試作と収支調査、RenderingはA/B描画経路調査、Validationはバグ再現テスト。試作は各worktreeのscratch/に置き、runtimeへ接続しない。
成果: 再現手順、baseline計測、根proxy対応率、現在の契約とコードの不一致。終了時間を決めるため2回の抽出手法試作を上限とし、どちらも採用条件未達なら下記fallbackへ進む。証拠なく「もう少し」で繰り返さない。

## 根の採用ゲートと代替手順
- 元アセットの低部（prepared local y≤3.6m）のalphaを考慮したmaskを正面/側面/上面から512²でレンダリング。camera・bounds固定、source/proxy両方を保存。木全体scaleで比較しない。
- 画面上の誤差許容幅は元根の代表半径とし、そのpixel値と実寸を記録。source maskのうち許容幅内にproxyがある面積割合≥90%、proxy maskのうちsourceから許容幅外にある面積割合≤10%を3方向すべて要求。これは幾何学近似の採用基準であり物理精度の証明ではない。
- 主要根10本（乱数seed831で選択、選択ID保存）を目視確認。枝を別根に接続する/地面に浮く/葉を円柱化する失敗があれば不採用。
- 自動抽出失敗時: 元GLBの主要根を直交ビューで追い、手作業のcenterline制御点JSONを作る。元画像上でsourceと重ねて同じ採用条件を適用。Blenderは利用可能なら補助、必須依存にはしない。
- 手動proxyも未達なら既存surface-sample方式を保持し、太さの幾何学対応はUNMETとして親に報告。倍率を本物の太い根と宣伝しない。他の独立作業は継続。proxy失敗を生成木で隠さない。

## P1: 共通基盤を直列で固定
親が共有契約とfixtureをcommit。次にPhysicsが設定API/stepIndexを実装し親が統合。その統合commit上でRenderingがfixtureの描画接続smokeを実装し親が統合。検証担当が3点を確認: reset state一致、人工円柱の描画/抵抗の位置一致、observationが次stepのstateを読むこと。
この間、親は未確定APIに依存するUIを並列編集しない。土砂観察粒子に必要なerosion/deposition per-step APIもここでsignature・buffer layout・所有者を確定。決定は01に記載。
API fixture smokeが失敗ならP1内で修正。P2の機能実装を先行しない。契約revisionとcommit hashを全workerへ送る。

## P2: 独立した修正の並列実装
Physics=左右独立性、収支、初期/境界濃度。Rendering=左右の影/反射/泡/根overlay混入と水面挙動。Validation=独立再現試験。親=確定APIのUI・測定・保存。各workerはこの段階だけ実装、将来gateへ勝手に進まない。
受入: 物理・描画A/B独立性、岸線符号、静水/沈降/供給試験。両岸前進しても収支に整合ならPASS可能。「なし側を必ず後退させる」修正は禁止。

## P3: 共通データに基づく拡張
Physics=採用済みproxy/解像度・減衰比較。Rendering=確定済みproxy表示・更新地形PBR・土砂marker。親=観測帯/視点/縮尺/履歴。根のデータが不採用の場合は既存方式で独立描画のみ継続し、対応項目は未達として残す。
侵食を見せるscenarioはP2の計測後に選ぶ。initial Cとboundary C、波/水位/周期/地形/森林幅を両ケース同一にし、未校正・探索した範囲を記録する。結果に応じてA/Bで係数を変えない。長時間計算で差を増やす場合も物理dtは不変。

## P4: 総合評価
P2/P3全変更を統合した単一commitで回帰、自然表示、thermal性能、操作を実行。同じGPUで複数workerの性能試験を同時実行しない。失敗箇所だけ修正後、影響する試験群を再実行。写真参照への近さと物理検証を別表にする。

## 数値受入（初期engineering基準、実測前の校正値ではない）
同一float32環境で短期CPU/GPU比較はabs(a-b)≤atol+rtol*max(abs(a),abs(b)):
| 成分 | atol | rtol |
| h,zb,initialZb [m] | 1e-5 | 1e-5 |
| qx,qz [m²/s] | 1e-5 | 1e-4 |
| ms,E,D [kg/m²] | 1e-5 | 1e-4 |
| boundary water [m] | 1e-5 | 1e-4 |
| boundary sediment [kg/m²] | 1e-5 | 1e-4 |
補正ledgerは0。NaN/Inf/負のstockはFAIL。長時間比較でこれを無条件に適用せず、保存則・解像度収束・時間履歴で別検証。
閉鎖系総量relative residual≤1e-5（基準質量=初期の水量、土砂は侵食可能bed在庫+浮遊量）。絶対残差も必ず記録。開放系はboundary ledger差引き残差を同じ基準で確認し、巨大な不動bed massだけを分母にして誤差を隠さない。
上記は科学精度保証ではない。失敗時は単位/精度/step数/独立解を調べる。テストを通すだけの閾値緩和は禁止。変更には親による理由とbefore/after記録が必要。

## 自然表示の固定評価
- viewport1440×960、devicePixelRatio1、seed831、同一case条件。P1で保存した全景cameraと岸際cameraをJSONから再使用。auto-fitで各caseの大きさを変えない。
- 時刻0/180/1080秒の最寄step、caseA/B、全景/接写を撮影。numbers/shoreline/heatmap/flow tracer/root overlayはoff、naturalのみ。通常の濁り表現はon。比較には必ず同じ波位相の組を追加。
- baselineとafterの1×10秒動画を同じstep範囲で保存。固定simulation frame captureとリアルタイム動画を区別。pixel変化量だけで「波が自然」を判定しない。
- 各画像で削れた/堆積した/濁りが通過した位置を座標付きで指摘できるか。指摘箇所のphysical deltaを独立記録と照合。存在しない差をtextureだけで作った場合FAIL。
- 物理的差がscreen1pixel未満なら、その全景を成功としない。接写で何cm/pixelか示す。診断用の差分画像は別保存し、natural画面に合成しない。
- 連続frameで泡が流れに逆行する、地面模様が滑る、根なし側に根の影が現れる、pauseでも進む場合FAIL。物理上の逆流そのものはFAILでない。
- 人間が補助線なしで識別できるという最終判断は、測定とAIレビューのみでは確定しない。レビュー可能な動画・画像をユーザーへ提示し、未確認ならHUMAN-REVIEW-PENDINGと記す。他の作業はそこで止めない。

## branchと統合
Pごとに基点commit Cを一つ固定。例 codex/p2-physics、codex/p2-rendering、codex/p2-validationと.worktrees/p2-*。既存パスを上書きしない。既存branchが別基点なら履歴を調べ、新しい名前を使う。
workerは担当ファイルの小さなcommitのみ。親はgit diff --name-only C..workerで所有権を確認し、列挙したcommitをphysics→rendering→validationで直列cherry-pickする。検証先の統合commitを記録。
失敗修正は現在の統合commitから新しいfix branchで所有者が行う。既に取り込んだ履歴を再cherry-pickしない。単なる競合回避のために機能を削らない。

## 証拠と再開
親所有docs/implementation-prompts/run-state.jsonを作成: schemaVersion,gate,contractCommit,integrationCommit,workers[{role,branch,worktree,base,head,status,nextAction}],tests[{id,status,evidence}],unmet,updatedAt。ここに秘密情報を入れない。
テストstatusはPASS/FAIL/NOT-RUN/NOT-REPRODUCED/BLOCKED-DEPENDENCY/HUMAN-REVIEW-PENDING。NOT-RUNをPASS扱いしない。checkpointはgate終了、worker完了、統合失敗、中断前に更新。
証拠JSON/CSVと小さい代表PNGはdocs/implementation-prompts/runs/<run-id>/に保存してcommit（既存/evidenceはignoredなので正本にしない）。動画など大きい証拠は/evidence/<run-id>/に残し、tracked manifestへ絶対path/size/SHA256/生成コマンドを記録。Gitだけで動画まで復元できるとは書かない。削除/上書きしない。
再開時はrun-state、git status、各head、manifest存在/hashを照合。記録と違えば勝手にresetせず差分を調べる。完成commitと証拠が揃う工程を再実装しない。走っていないagentへ途中から指示する時はgateとnextActionを再送する。
同じ原因の修正2回で改善しない場合、親が再現最小例と仮説を見直す。無関係な機能追加で回避しない。真にユーザー判断が必要な科学的tradeoff以外は調査を継続する。

## 完了報告
必須項目それぞれ実装commit・検証・自然表示証拠・限界を列挙。未達は未達のまま示す。「全実装完了」は未達0かつ必須試験PASSの時のみ。GPUが使えなかった場合はCPUテスト通過のみと明記する。
