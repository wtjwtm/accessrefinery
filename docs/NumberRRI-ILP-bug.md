# NumberRRI 归零：一次静默的 ILP 失败（前因后果与修复）

日期：2026-10-09 · 影响配置：Original（`-Dopt.pruner=false`）与 MiningOptimized（`-Dopt.pruner=false -Dopt.refinement=true`）

## 一句话

归约阶段建 EC 划分时，引擎里同时存在**两个 `MCPBitVector` 类型的标签**（策略标签 `remainingPolicy` 和引擎自己加的 `logicTrue`），代码却用"遍历到最后一个"来挑集合覆盖的 universe（全集）。两个标签的哈希值是各自 BDD 的**节点编号**，于是这个"最后一个"取决于 BDD 的分配顺序——碰上 `logicTrue` 时全集被放大到整个语义空间（442 个原子，而策略本身只有 301 个），发现项永远盖不住多出来的那个原子，CBC 返回 `INFEASIBLE`；而 `ILPSolver` 只在 `OPTIMAL` 时填结果，其余状态**静默返回空 map**。最终归约结果为空、`NumberRRI` 写成 0，全程没有任何报错或告警。

## 症状

- `summary.txt` 第 3 列 `NumberRRI = 0`，而同一行的第 1 列 `NumberStatement = n`、第 2 列 `NumberMCI = n²` 都正常；即**该 policy 的 `NN_allow_result.json` 是一个空 Finding 列表**——工具对外宣称"归约到覆盖全策略的最小发现集"，实际输出空集。
- 日志一切正常：`[6/6] finish findings reduction : 0`，没有异常、没有 warning。
- 只发生在 pruner 关掉的两条配置上；PruningReducer / IncrementalMCP 在同一批输入上都会先走到 `essential findings already cover all policy` 提前返回，ILP 根本不执行。

已知受影响的格（45 条 (dataset, policy) 里 3 条）：

| 归档 | 数据集 | policy | 归档值 | 修复后 |
|---|---|---|---|---|
| `..._Original_10rs` | Scalability_06Keys | 1 | 0 | 1 |
| `..._Original_10rs` | Scalability_06Keys | 3 | 0 | 3 |
| `..._MiningOptimized_10rs` | Scalability_06Keys | 1 | 0 | 1 |
| `..._Original_10rs` | Scalability_05Keys∗ | 6 | 6（旧代码对） | 6（当前代码曾是 0） |

## 根因

### 第一层：universe 取错（`AccessRefinery.reducingIntents`）

```java
Set<Label> mcpVars = new HashSet<>();
for (MCPIntent f : candidates) mcpVars.add(new IntentOrPolicyLabel.Builder().setFinding(f).build());
mcpVars.add(new IntentOrPolicyLabel.Builder().setMCP(remainingPolicy).build());   // 策略标签

ECEngine ECEngine = new ECEngine(mcpVars, logicTrue);   // logicTrue = MCPFactory.getOne()

for (var entry : ECEngine.getECs().entrySet()) {
    IntentOrPolicyLabel var = (IntentOrPolicyLabel) entry.getKey();
    if (var.getVarType() == VarType.FINDING)       findingsVarToECs.put(var, entry.getValue());
    else if (var.getVarType() == VarType.MCPBitVector) policyECs = entry.getValue();   // ← 取"最后一个"
}
ILPSolver.solve(findingsVarToECs, policyECs);
```

引擎里 `MCPBitVector` 类型的标签恰好有两个：调用方放进来的策略标签，和引擎构造时自己 add 的 `logicTrue`（`MCPFactory.getOne()`，逻辑真，覆盖整个空间）。`getECs()` 返回的是 `HashMap<Label, Set<Integer>>`，循环里"最后一个 MCPBitVector"究竟是哪一个，取决于 **HashMap 的迭代顺序**。

### 第二层：静默失败（`ILPSolver.solve`）

```java
MPSolver.ResultStatus status = solver.solve();
Map<Object, Set<Integer>> selectedSubsets = new HashMap<>();
if (status == MPSolver.ResultStatus.OPTIMAL) { /* 填结果 */ }
return selectedSubsets;      // 非 OPTIMAL：返回空 map，无日志、无异常
```

`INFEASIBLE`（有元素无人覆盖）和 `FEASIBLE`（未证最优）、`ABNORMAL` 全都走同一个出口：调用方拿到的空 map 与"没有发现项需要选"无法区分。

### 为什么"最后一个"会变、且不按输入讲道理

`IntentOrPolicyLabel.hashCode()` 对 `MCPBitVector` 类型的标签委托给 `MCPBitVector.hashCode()`，后者返回底层 BDD 的哈希——在 JavaBDD 里就是 **BDD 节点在工厂里的编号**（`accessrefinery/bdd/src/main/java/net/sf/javabdd/JFactory.java:514`：`public int hashCode() { return _index; }`）。

于是：

- 同一个 jar + 同一份输入 → 节点分配顺序固定 → 迭代顺序固定 → **结果稳定可复现**（不是每次跑都随机）。
- 但任何改变 BDD 构造顺序的代码改动，都可能让某些输入的两个标签**换位**，把原本正常的 policy 翻进失败状态，反之亦然。

实测的换位：同一输入（05Keys∗ policy 6）、同一台机器、同一个 JDK：

| 代码 | 取到的 universe | 结果 |
|---|---|---|
| 旧树 `f32eae8`（2026-09-20，ECEngine 用 `ImmutableSet.builder().addAll(labels).add(trueLabel)`） | 策略标签，301 个原子 | 6 ✅ |
| 当前树 `acbef91`（2026-10-09，ECEngine 重写为 `IncrementalECPartition`，构造里改用 `ImmutableSet.copyOf(HashSet)`） | `logicTrue`，442 个原子 | 0 ❌ |

两者只是标签被吸收的**顺序**不同，最终 EC 划分就不同，节点编号随之改变，迭代顺序翻转。修复前打印的证据：

```
[DBG-LBL] bitVecEntries=2  lastBitVecIsTrueLabel=true  activeAtoms=442
[DBG-BDD] remainingPolicy.satCount=301  unionFindings.satCount=441  gap.satCount=0
subsets=36  universe=442  status=INFEASIBLE   →  findings reduction : 0
```

`gap.satCount=0` 说明发现项**已经完整覆盖了策略**（301 全在内），失败纯粹来自多出来的那 141 个只在 `logicTrue` 里、不在策略里的原子。

## 何时引入

| 时间 | 事件 |
|---|---|
| 2026-09-14 | 仓库第一个提交 `a61e2bb`。这两段代码（"取最后一个 MCPBitVector" 与 `if (status == OPTIMAL)`）**从这一刻起就在**，缺陷与归约器同龄。 |
| 2026-09-23 | 归档 run（`~/exp/rerun10b/BR`，`--round 10`）里 **06Keys policy 1、3 已经是 0**；当时用的是旧 ECEngine，"最后一个"碰巧是 `logicTrue`。也就是说 0 不是这次重写才出现的。 |
| 2026-09-26 | PruningReducer / IncrementalMCP / MiningOptimized 的归档 run，MiningOptimized 06Keys policy 1 同样是 0。 |
| 2026-10-09 | `acbef91` 把 ECEngine 重写为 `IncrementalECPartition`（增量 EC 引擎，论文 Technique 1）。标签处理顺序改变，**05Keys∗ policy 6 也被翻进失败状态**，问题从"归档里两格历史遗留"变成"当前代码重跑就对不上归档"。 |

## 修复

两处最小改动（`accessrefinery/refinery/src/main/java/org/iam/core/`）：

1. **`AccessRefinery.reducingIntents`**——不再按类型挑"最后一个"，而是留下策略标签本身，按内容精确取；取不到就抛，不再静默。

   ```java
   IntentOrPolicyLabel policyVar = new IntentOrPolicyLabel.Builder().setMCP(remainingPolicy).build();
   mcpVars.add(policyVar);
   ...
   Set<Integer> policyECs = ecs.get(policyVar);
   if (policyECs == null) throw new IllegalStateException("the remaining policy is missing from its EC partition");
   ```

2. **`ILPSolver.solve`**——非 `OPTIMAL` 时打 warning（状态、子集数、universe 大小）。仍返回空集，因为 pruner 开启时"essential 已覆盖全部、没有可选的子集"是合法结果；但从此不再无声。

## 验证（同一台机器，fix 前后各跑一轮）

BR / AR / AI × 05Keys / 06Keys / 05Keys∗，`--round 1`，逐格对比两份 summary：

- **只有 3 格 c3 变了**，其余 42/45 逐格相同（无连带影响）：BR/06Keys p1 `0→1`、p3 `0→3`；BR/05Keys∗ p6 `0→6`。
- 全日志 **0 条** `set cover did not reach an optimal solution`——每次 ILP 都拿到了 `OPTIMAL`。
- AR / AI 的 c3 完全不动（提前 return，ILP 未执行）。
- MiningOptimized / 06Keys p1 `0→1`。
- `mvn -o test`：20/20 通过。
- 与归档 c3 对比：05Keys 15/15、05Keys∗ 15/15 完全一致；06Keys 13/15，差的正是归档里本来就存在的两个 buggy 0。

## 影响面与已重新生成的数据

- **没有任何绘图脚本读第 3 列**（各 extractor 只取第 5、6、7、8、9 列）；20rs 归档（shipped 图的另一路输入）9 个目录 × 15 行**没有一行 c3 = 0**。所以这批图从来没有被这个 bug 画错。
- 2026-10-09 用修复后的 jar 重跑了 **10rs 的 Original（三个数据集）与 MiningOptimized（06Keys）**，并替换了 `results/` 与 `archive_results_journal/` 两份拷贝；旧数据备份在 `_repo_trash/20261009-1649/10rs-Original-before-fix/`。
- `extract_optimization_pipeline_10rs.sh` 重新生成后，**只有** `bar3_*`、`seg_*`（Original 的 c5）和 `enc_06`（MiningOptimized 的 c6/c8）变化，`p2_*`、`enc_05/07`、`rw_*` 逐字节不变；据此重画了 **RQ7**（三阶段柱状图）与 **RQ9**（占比柱状图）。
- 柱高的变化幅度（−17% ~ +5%）**主要是重跑当天的机器状态差异**，不是这次修复本身——修复影响的 ILP 那一步只占总时间的千分之几；修复真正改变的是数据里的 `NumberRRI`。

## 遗留

1. 20rs 归档、PruningReducer / IncrementalMCP / MiningOptimized 的另外两个数据集都**未重跑**。因此 `RQ7` 图里现在 Original 一列是 2026-10-09 的，另两列仍是 2026-09-26 的；定稿前建议整体重跑一次，让同一张图来自同一批 run。
2. 归档里原本的 0 是**真实发生过的输出**，替换后这段历史只留在备份目录里。
3. 同类隐患：只要有"按类型从 map 里挑一个"的写法，而 key 的哈希又依赖 BDD 节点编号，就可能再次出现"代码一改、某些输入的结果悄悄换位"。归约路径现在改为按内容取，但值得全局搜一遍同类模式。
