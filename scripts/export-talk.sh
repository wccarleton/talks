#!/usr/bin/env bash
set -euo pipefail

input="${1:-slides/latent_human_influence.qmd}"
deck="$(basename "$input" .qmd)"
input_dir="$(dirname "$input")"
out_root="${TALKS_EXPORT_DIR:-export}"
out_dir="${out_root}/${deck}"

mkdir -p "${out_dir}/offline" "${out_dir}/pptx"

export TALKS_EXPORT_REMOTE_IMAGES=1

quarto render "$input" \
  --profile export \
  --to revealjs \
  --output-dir "${out_dir}/offline"

quarto render "$input" \
  --profile export \
  --to pptx \
  --output-dir "${out_dir}/pptx"

printf 'Exported %s\n' "$input"
printf '  Offline HTML: %s/offline/%s/%s.html\n' "$out_dir" "$input_dir" "$deck"
printf '  PowerPoint:   %s/pptx/%s/%s.pptx\n' "$out_dir" "$input_dir" "$deck"
