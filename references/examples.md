# Labloop — Example Configurations

These are examples of `labloop.md` for different domains. Use them as inspiration when helping users set up their experiments.

---

## Example 1: ML Model Training (autoresearch-style)

```markdown
# labloop — Experiment Config

## Research Goal

Minimize validation bits-per-byte (val_bpb) for a small GPT model on text data.

## Files

### Editable (agent can modify)
- `train.py`

### Read-only (do NOT modify)
- `prepare.py`
- `pyproject.toml`

## Experiment

### Run command
```bash
uv run train.py
```

### Metric
- **Name**: val_bpb
- **Direction**: lower_is_better
- **Extract command**: `grep "^val_bpb:" labloop-run.log | awk '{print $2}'`

### Timeout
600 seconds per experiment

## Constraints
- Do not install new packages
- Do not modify the evaluation harness in prepare.py
- VRAM increase is acceptable for meaningful gains but should not blow up dramatically

## Research Hints
- Try adjusting DEPTH, ASPECT_RATIO, learning rates
- Experiment with different activation functions (ReLU squared, SwiGLU, GELU)
- Try different window patterns (all L, all S, mixed)
- Optimizer hyperparameters: betas, weight decay, warmup ratio
- Consider architectural changes: different attention patterns, MLP widths
```

---

## Example 2: Algorithm Performance Optimization

```markdown
# labloop — Experiment Config

## Research Goal

Minimize average query latency for the search engine's ranking function.

## Files

### Editable (agent can modify)
- `src/ranker.py`
- `src/scoring.py`
- `src/cache.py`

### Read-only (do NOT modify)
- `benchmarks/bench_ranking.py`
- `tests/`
- `src/index.py`

## Experiment

### Run command
```bash
python benchmarks/bench_ranking.py --queries 10000
```

### Metric
- **Name**: avg_latency_ms
- **Direction**: lower_is_better
- **Extract command**: `grep "avg_latency_ms:" labloop-run.log | awk '{print $2}'`

### Timeout
120 seconds per experiment

## Constraints
- All existing tests must still pass (run `pytest tests/` before committing)
- Do not change the public API signatures in ranker.py
- Memory usage should stay under 2GB

## Research Hints
- Profile hot paths with cProfile first
- Consider caching intermediate scoring results
- Try different data structures for the priority queue
- Batch scoring operations where possible
- Consider SIMD-friendly data layouts with numpy
```

---

## Example 3: Frontend Performance (Lighthouse Score)

```markdown
# labloop — Experiment Config

## Research Goal

Maximize Lighthouse performance score for the landing page.

## Files

### Editable (agent can modify)
- `src/components/*.tsx`
- `src/styles/*.css`
- `next.config.js`

### Read-only (do NOT modify)
- `src/lib/api.ts`
- `public/`
- `tests/`

## Experiment

### Run command
```bash
npm run build && npx lighthouse http://localhost:3000 --output=json --output-path=lighthouse.json --chrome-flags="--headless" && node -e "const r=require('./lighthouse.json'); console.log('perf_score:', r.categories.performance.score * 100)"
```

### Metric
- **Name**: perf_score
- **Direction**: higher_is_better
- **Extract command**: `grep "perf_score:" labloop-run.log | awk '{print $2}'`

### Timeout
180 seconds per experiment

## Constraints
- Visual appearance must not change (no layout shifts)
- All existing tests must pass
- Do not remove any features or content

## Research Hints
- Lazy load below-fold components
- Optimize images: format, sizing, loading strategy
- Reduce JavaScript bundle size
- Minimize CSS — remove unused styles
- Consider code splitting for heavy components
```

---

## Example 4: Prompt Engineering

```markdown
# labloop — Experiment Config

## Research Goal

Maximize classification accuracy of the LLM prompt on the test dataset.

## Files

### Editable (agent can modify)
- `prompt.txt`
- `few_shot_examples.json`

### Read-only (do NOT modify)
- `evaluate.py`
- `data/test_set.jsonl`

## Experiment

### Run command
```bash
python evaluate.py --prompt prompt.txt --examples few_shot_examples.json --dataset data/test_set.jsonl
```

### Metric
- **Name**: accuracy
- **Direction**: higher_is_better
- **Extract command**: `grep "^accuracy:" labloop-run.log | awk '{print $2}'`

### Timeout
300 seconds per experiment

## Constraints
- Do not modify evaluate.py or the test dataset
- Prompt must stay under 2000 tokens
- Few-shot examples limited to 5

## Research Hints
- Try chain-of-thought prompting
- Experiment with different few-shot example selection
- Try structured output formats (JSON vs free text)
- Test different instruction phrasings
- Add explicit edge case handling in the prompt
```

---

## Example 5: Compiler / Build Optimization

```markdown
# labloop — Experiment Config

## Research Goal

Minimize binary size while maintaining benchmark performance within 5% of baseline.

## Files

### Editable (agent can modify)
- `Cargo.toml` (profile settings only)
- `.cargo/config.toml`
- `build.rs`

### Read-only (do NOT modify)
- `src/**/*.rs`
- `benches/`

## Experiment

### Run command
```bash
cargo build --release 2>&1 && ls -la target/release/myapp | awk '{print "binary_bytes:", $5}' && cargo bench -- --output-format bencher 2>&1 | tee -a /dev/stderr | grep "test .* bench:" | awk '{sum+=$5; n++} END {print "avg_bench_ns:", sum/n}'
```

### Metric
- **Name**: binary_bytes
- **Direction**: lower_is_better
- **Extract command**: `grep "binary_bytes:" labloop-run.log | awk '{print $2}'`

### Timeout
300 seconds per experiment

## Constraints
- Benchmark performance must stay within 5% of baseline avg_bench_ns
- Do not modify source code — only build configuration
- Must compile without errors on stable Rust

## Research Hints
- Try opt-level variations (z, s, 2, 3)
- Experiment with LTO (thin, fat)
- Try codegen-units = 1
- Test strip = true / strip = "symbols"
- Consider panic = "abort"
```
