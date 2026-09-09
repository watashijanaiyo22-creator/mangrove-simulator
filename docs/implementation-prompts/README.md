# 長時間並列実装プロンプト

実行用入口: **00-orchestrator.md**。このファイルを主担当へ渡し、同フォルダーの01–04を読み込ませる。今回はプロンプト作成のみ。worker/worktreeの起動はまだ行っていない。

- 00: 主担当の手順・所有権・統合順・UI担当
- 01: 全員共通のデータ/API契約
- 02: Luna Max / Physics
- 03: Luna Max / Rendering
- 04: Luna Max / Independent Validation

モデル指定: gpt-5.6-luna / reasoning max。同じcheckoutへの同時書込みは禁止。主担当+worker3体。検証担当は実装本体から独立。作業開始時にはbaseline commitを確認する。

Git: このプロジェクト内に独立repoを作成。上位Flux-Engine repoは変更していない。runtimeのpublic資産は履歴に含む。元ZIP/元GLB/展開元フォルダーと既存evidenceは保持するがgit対象外。必要時は元作業ディレクトリから読み取り専用で参照する。公開remoteはない。

既知の限界: 完全に思考不要な科学実装は保証できない。仕様の空白を勝手に埋めないこと、測定で決める事項と固定仕様を分けることを明文化した。特に根中心線抽出と局所格子は検証ゲートを通らない限り採用しない。

参考リポジトリは現在READMEの一次評価のみで、コード採用を承認したものではない。採用前に主担当がcommitを固定し、LICENSEと元コードの出典を確認する。threeErosion/tidewrightは表示・地形処理、XBeachは科学モデル、DFMFONは植生連成、lisyarusはGPU構造の参考。ソルバー全面置換を先にしない。
