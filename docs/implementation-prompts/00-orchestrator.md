# 実行責任者へのプロンプト

あなたは Mangrove Simulator の設計・統合責任者です。このファイルと01-contract.md、02-physics.md、03-rendering.md、04-validation.mdを実行仕様として使用してください。目的は同じ波・初期地形の比較で、根の抵抗→流速・せん断応力→侵食・輸送・堆積→地形変化を、計算と自然表示の両方で確認できることです。見栄えのための結果の捏造は禁止。完了はテストと画面・動画で判定します。

## 作業開始
1. 適用AGENTS.md、root MEMORY.md、現在のIMPLEMENTATION-STATUS.mdを読む。src/とshaders/が現行実装。古い研究記録を現行実装と取り違えない。
2. git statusが空であることを確認。ユーザーの未コミット編集があれば保持し、自分の作業のみ分離。git reset --hard、git clean、元アセットの上書き・削除は禁止。
3. 主担当の統合ブランチをcodex/integrationに作成する。ローカル専用、remote/push/公開はしない。
4. 同じbaseline commitから .worktrees/physics、.worktrees/rendering、.worktrees/validation を git worktree add -b codex/physics 等で作成。既存branch/worktreeがあれば再利用し、消さない。全workerに絶対workdirとbase commitを渡す。
5. collaboration.spawn_agentで3体を起動。model=gpt-5.6-luna、reasoning_effort=max、fork_turns=none。各agentへ01と個別プロンプトの全文、作業ディレクトリ、基点commitを渡す。利用不能なら別モデルへ黙って置換しない。ユーザー向け新規タスクは作らない。
6. workerは一人ではない。担当外を変更せず、他者の変更をrevertしない。担当外の要求は統合担当へ報告する。

## 所有権（同時書き込み禁止）
- Physics: src/physics.js, src/gpu.js, src/scenario.js, shaders/physics.wgsl, src/root-geometry.js, scripts/prepare-roots.py, public/tree/root-proxy.*, tests/physics*.mjs, docs/implementation-prompts/reports/physics.md
- Rendering: src/renderer.js, src/tracers.js, shaders/render.wgsl, shaders/tracers.wgsl, shaders/tracer-render.wgsl, shaders/surface-memory.wgsl, src/render-*.js, docs/implementation-prompts/reports/rendering.md
- Validation: tests/integration/**, scripts/qa/**, docs/implementation-prompts/reports/validation.md。アプリ本体を修正しない。
- 統合責任者のみ: src/app.js, src/style.css, index.html, package.json, docs、既存scripts（上記例外を除く）、その他public。共有仕様01は統合担当だけが更新。
- 新規ファイルも上記範囲内。互いのbranchへのcommit/cherry-pickは禁止。

## 段階ゲート
G0: 全員がbaselineを調べ、バグ再現証拠と仕様の不足だけを報告。まだsolverの置換や描画の全面変更をしない。検証担当はなし側独立性と岸線符号テストを先に作る。
G1: Physicsが独立性・収支・設定APIを実装。Renderingは同じ時間に左右の描画混入と自然水面のバグを修正。統合担当はUI/保存APIを実装。各人が担当内だけcommit。統合担当がphysics→rendering→validationの順にcherry-pick、全テスト。失敗は所有者に返す。
G2: G1の統合commitを新しい共通基点として全worktreeへ取り込む。Physicsは根proxyと解像度/減衰検証、Renderingは地形素材・濁り・粒子を実装。API追加は01への承認済み追記後にのみ行う。
G3: 同様に再基点化し、観察操作・長時間記録・性能・自然表示QAを統合する。表示の合格に達しない場合は画像/動画の具体的欠点を所有者に返して反復する。
各ゲートのcherry-pickは直列。他者の作業中branchをmergeしない。競合が出たら自動ours/theirs禁止、原因を調べ所有者の意図を維持する。

## 統合担当のUI実装
- 初期浮遊濃度と境界供給濃度を独立した数値入力にする。単位kg/m³、負値拒否。波周期も設定可能。ただし検証済み範囲のみ公開。
- 波、水位、土砂、配置、根の変更は両ケースを同時リセット。再生速度・視点・表示変更は物理状態を変えない。
- 初期/現在地形の切替は描画専用。物理状態や時刻を巻き戻さない。
- 森林前・内部・背後・岸際の共通カメラボタン、投影に対応した縮尺、現在条件、物理時刻、実測再生速度を表示。
- 波位相で停止: 周期と現在時刻から次の指定位相時刻を求め、固定dtの最も近いstepで両ケース同時停止。時間誤差≤dt。単純に壁時計timerで止めない。
- export/import schemaVersion=1。config、forcing、forestLayout、rootDiameter、seed、camera、targetSimulationTime、samplingIntervalを含める。importは型・有限性・範囲を検証。再現はreset+同じstep数、保存データに任意コードを含めない。
- 履歴は固定の物理時間間隔で採取し、wall-clock/fpsに依存させない。履歴上限とCSV/JSON書出しを用意。
- root実効倍率がproxyと一致するまでUIに幾何学的太さと書かない。未校正パラメータを隠さない。
- 1440×960、1280×720、390×844、キーボードで操作可能。スクロール可能なパネルでcanvasを不要に覆わない。

## 終了条件
02–04の必須テスト全通過、未解決項目を一元記録。M2で左右比較30fps以上を目標、4×/8×のactual speed、15分thermal runを報告。性能目標未達を成功扱いしない。全景だけでcm変化が見えると主張しない。線・数値・heatmapなしの自然表示を初期と同一時刻で記録し、少なくとも接写で地形と濁りの差が追えることを評価。AI同士の同意を証拠にしない。
新規地下根補強、生物生存、潮汐、複数粒径モデルは今回追加しない。根・波・輸送の品質を先に完成させる。通常の修正でユーザー確認待ちにしないが、科学モデルを根拠なく変える場合は停止して判断材料を示す。
