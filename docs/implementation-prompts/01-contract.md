# 固定共有仕様 v2

全worker必読。05の受入条件を併読。変更が必要なら変更案を親へ送る。自分でstride/binding/APIを変更しない。

## 現行データ
座標: xは沖→岸、yは標高、zは沿岸。SI単位。CONFIG既定はnx120,ny80,dx0.6m,dt0.018s。セル中心(x+.5)*dx。水面=zb+h。
Cell=Float32×12=48bytes。0:h[m],1:qx[m²/s],2:qz,3:ms[kg/m²],4:zb[m],5:累積deposition[kg/m²],6:累積erosion[kg/m²],7:initialZb,8:boundaryWater[m],9:boundarySediment[kg/m²],10:positivityWaterCorrection[m],11:sedimentCorrection[kg/m²]。最後の成分をreservedと扱わない。
Root field=vec4/cell、初期地盤から高さ[0,.3,.6,1.2,3.6]mの4band。各値は投影面積/平面面積。埋没・水没割合は物理側で評価。見えていない矩形forest dragは禁止。
A=case0 mangrove、B=case1 bare。state、observation、tracer、reflection、shadow、depthはケースごとに独立。共有可は読み取り専用mesh/materialと同期cameraのみ。
Flow q/hと波高H、波エネルギーを混同しない。shorelineは固定datum=0のzb等高線。x増加が後退、x減少が前進。瞬時wet/dry境界と分ける。等高線なしはnull、0mと報告しない。

## 互換APIと追加API
Simulation.create(device,roots,c=CONFIG)、reset(tide=0)、step(count,options)、read(caseID)、current(caseID)を維持。
Physicsはreset(tide=0,{initialConcentration=c.concentration}={})へ後方互換拡張。initialStateにも同じ第3引数を追加。
step options追加: boundaryConcentration（既定c.concentration）、period（既定c.period）。既存wave/tide/vegetation/boundary/sediment/dtを維持。実運用dtはCONFIG値のまま、検証用以外に拡大しない。
Simulation.paramsDataのGPU uniformは既存80bytesを維持。p.forcing.w=period、p.sediment.w=boundaryConcentration。initialConcentrationはreset時のCPU初期化のみ。
Renderer.draw(caseID,mode=0,shore=true)維持。追加properties showInitialBed=false, sedimentMarkersEnabled=false。初期表示時もhydro bufferを書き換えない。不要な旧地形依存効果は表示説明に明記。
測定APIは親がsrc/measurements.jsに実装しexport measureState(state,c,{datum:0})。戻り値にcurrentShoreline/initialShoreline配列(null許可)、各帯のmeanSpeed/rmsSpeed/bedShear、eroded/deposited/netBedMass。時間波高測定はetaRms=std(eta)、規則波の等価波高H_equiv=2sqrt(2)*etaRmsとする。一般の不規則波のH_rmsやHsと同一視しない。
UIテストhookはwindow.lab: sim,device,CONFIG,pause(),resume(),reset(),advance(steps,options),read(),changeForest(layout,diameter)。新hookは親が追加、既存を壊さない。

## 検証資産
元ZIP/GLBを改変しない。public/treeとpublic/materialsはbaselineに含まれる。元ZIP/GLBはgitignore対象なのでworkerで必要なら親が絶対パスを読み取り専用で渡す。新root proxyのみPhysicsの所有。runtimeのThree.js移行は禁止。現WebGPUを維持し、資料のコード導入は親のlicense確認後。

## 更新タイミング（固定）
- 各step: t_nのforcing→hydro+sediment+bed更新→observation更新→phase反転→stepIndex増加。observationは更新後stateだけを読む。
- reset: stepIndex=0、time=0、両phase同じ初期state、全observation/marker/historyをclear。generationを増やし古い非同期read結果を破棄。
- 時刻の正本は整数stepIndex。time=stepIndex*dt。履歴はstepIndex%samplingStrideSteps==0で取得。実行batchは観測・停止境界を跨がない。
- GPU readは対象generation/stepIndexとセットで返す。別stepのA/Bを同一時刻として集計しない。
- 領域別測定帯をP1で物理座標として固定し、全比較条件で使う。乾燥cellは速度集計から除きwet areaも併記。全域と帯別の土砂収支を混同しない。
- 累積E/Dの差分は同一case・連続stepから計算。瞬間fluxが必要ならPhysics所有の別buffer/API追加を親が承認してから使う。RenderingがCPU readbackの壁時計差分から粒子発生量を推測しない。

## P1 fixture
親所有tests/contracts/にlinear-slope、still-water、deposition-only、single-rootの小規模JSON fixtureを作る。各fixtureにunits、config、stateStride、expected invariants、SHA256。root中心線fixtureは人工の単一円柱でありGLB抽出成功を意味しない。Physics→renderer接続をこのfixtureでsmokeし、未実装hookに依存したままP2を開始しない。
