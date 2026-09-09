# 実行責任者へのプロンプト

あなたは Mangrove Simulator の設計・統合責任者です。このファイルと01-contract.md、02-physics.md、03-rendering.md、04-validation.md、05-gates-and-recovery.mdを実行仕様として使用してください。目的は同じ波・初期地形の比較で、根の抵抗→流速・せん断応力→侵食・輸送・堆積→地形変化を、計算と自然表示の両方で確認できることです。見栄えのための結果の捏造は禁止。完了はテストと画面・動画で判定します。

## 作業開始
1. 現在有効な指示とIMPLEMENTATION-STATUS.mdを読む。以前のAGENTS.md指示はユーザーにより撤回されているため、旧MEMORY/AGENTSルーティングを復活させない。src/とshaders/が現行実装。古い研究記録を現行実装と取り違えない。
2. git statusが空であることを確認。ユーザーの未コミット編集があれば保持し、自分の作業のみ分離。git reset --hard、git clean、元アセットの上書き・削除は禁止。
3. 主担当の統合ブランチをcodex/integrationに作成する。ローカル専用、remote/push/公開はしない。
4. 先に05のP0/P1を実行する。P0は独立した調査・試験のみ並列可。機能の並列実装はP1の実データfixture・API smoke通過後に開始する。
5. 実装workerはcollaboration.spawn_agentで3体。model=gpt-5.6-luna、reasoning_effort=max、fork_turns=none。各agentへ01、05、個別プロンプトの全文、絶対workdir、基点commit、今回の許可gateとwrite setを渡す。利用不能なら黙って別モデルへ置換しない。ユーザー向け新規タスクは作らない。worktree/branchの命名と更新は05に従う。
6. workerは一人ではない。担当外を変更せず、他者の変更をrevertしない。担当外の要求は統合担当へ報告する。

## 所有権（同時書き込み禁止）
- Physics: src/physics.js, src/gpu.js, src/scenario.js, shaders/physics.wgsl, src/root-geometry.js, scripts/prepare-roots.py, public/tree/root-proxy.*, tests/physics*.mjs, docs/implementation-prompts/reports/physics.md
- Rendering: src/renderer.js, src/tracers.js, shaders/render.wgsl, shaders/tracers.wgsl, shaders/tracer-render.wgsl, shaders/surface-memory.wgsl, src/render-*.js, docs/implementation-prompts/reports/rendering.md
- Validation: tests/integration/**, scripts/qa/**, docs/implementation-prompts/reports/validation.md。アプリ本体を修正しない。
- 統合責任者のみ: src/app.js, src/measurements.js, src/style.css, index.html, package.json, docs、既存scripts（上記例外を除く）、その他public。共有仕様01は統合担当だけが更新。
- 新規ファイルも上記範囲内。互いのbranchへのcommit/cherry-pickは禁止。

## 段階ゲート
正式な実行順は05のP0→P1→P2→P3→P4。個別プロンプトの旧G0/G1/G2/G3は作業分類であり開始許可ではない。P0はG0調査、P2はG1修正、P3はG2拡張、P4はG3総合検証に対応する。
同じ統合commitからgate別の新branch/worktreeを作る。統合済みのworker commitを次gateで再度cherry-pickしない。API依存のある作業はfixtureと契約が届くまで開始禁止。親も未確定APIを推測してUIを実装しない。

## 統合担当のUI実装
- 初期浮遊濃度と境界供給濃度を独立した数値入力にする。単位kg/m³、負値拒否。波周期も設定可能。ただし検証済み範囲のみ公開。
- 波、水位、土砂、配置、根の変更は両ケースを同時リセット。再生速度・視点・表示変更は物理状態を変えない。
- 初期/現在地形の切替は描画専用。物理状態や時刻を巻き戻さない。
- 森林前・内部・背後・岸際の共通カメラボタン、投影に対応した縮尺、現在条件、物理時刻、実測再生速度を表示。
- 波位相で停止: 周期と現在時刻から次の指定位相時刻を求め、固定dtの最も近いstepで両ケース同時停止。時間誤差≤dt。単純に壁時計timerで止めない。
- export/import schemaVersion=1。config、forcing、forestLayout、rootDiameter、seed、camera、targetStep（整数）、samplingStrideSteps（整数）、sourceCommitを含める。importは型・有限性・範囲を検証。再現はreset+同じstep数、保存データに任意コードを含めない。
- 履歴は固定の物理時間間隔で採取し、wall-clock/fpsに依存させない。履歴上限とCSV/JSON書出しを用意。
- root実効倍率がproxyと一致するまでUIに幾何学的太さと書かない。未校正パラメータを隠さない。
- 1440×960、1280×720、390×844、キーボードで操作可能。スクロール可能なパネルでcanvasを不要に覆わない。

## 終了条件
02–04の必須テスト全通過、未解決項目を一元記録。M2で左右比較30fps以上を目標、4×/8×のactual speed、15分thermal runを報告。性能目標未達を成功扱いしない。全景だけでcm変化が見えると主張しない。線・数値・heatmapなしの自然表示を初期と同一時刻で記録し、少なくとも接写で地形と濁りの差が追えることを評価。AI同士の同意を証拠にしない。
新規地下根補強、生物生存、潮汐、複数粒径モデルは今回追加しない。根・波・輸送の品質を先に完成させる。通常の修正でユーザー確認待ちにしないが、科学モデルを根拠なく変える場合は停止して判断材料を示す。
