#!/usr/bin/env bash
#
# scaffold-component.sh — generate the testable + storybookable component trio:
#   <Name>.tsx           prop-driven component (no API/router imports)
#   <Name>.stories.tsx   Default + Empty stories, fn() for handlers
#   <Name>.test.tsx      renderWithProviders, asserts render
#
# Usage:
#   scripts/scaffold-component.sh <ComponentName> [target-dir]
#
#   <ComponentName>  PascalCase name (required), e.g. TodoList
#   [target-dir]     Directory to create the files in (default: current dir)
#
# Refuses to overwrite existing files. Assumes a "@/" alias to src/ and that
# the harness from SCAFFOLD.md exists (@/test/utils, @/msw/fixtures).
set -euo pipefail

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

NAME="${1:-}"
DIR="${2:-.}"
[ -n "$NAME" ] || die "component name required — usage: scaffold-component.sh <ComponentName> [target-dir]"
# Locale-proof PascalCase check: an explicit uppercase set, not the [A-Z] range
# (in some locales [A-Z] also matches lowercase letters).
case "$NAME" in
  [ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) : ;;
  *) die "component name must be PascalCase (got '$NAME')" ;;
esac

mkdir -p "$DIR"
COMPONENT="$DIR/$NAME.tsx"
STORIES="$DIR/$NAME.stories.tsx"
TEST="$DIR/$NAME.test.tsx"
for f in "$COMPONENT" "$STORIES" "$TEST"; do
  [ -e "$f" ] && die "refusing to overwrite existing file: $f"
done

cat > "$COMPONENT" <<EOF
export interface ${NAME}Props {
  // data in
  label: string;
  // callbacks out — never call the API or router from here
  onAction: () => void | Promise<unknown>;
}

export function ${NAME}({ label, onAction }: ${NAME}Props) {
  return (
    <button type="button" onClick={onAction}>
      {label}
    </button>
  );
}
EOF

cat > "$STORIES" <<EOF
import type { Meta, StoryObj } from "@storybook/react";
import { fn } from "@storybook/test";
import { ${NAME}, type ${NAME}Props } from "./${NAME}";

// Typed from the component's exported props, not \`typeof ${NAME}\`.
const meta: Meta<${NAME}Props> = {
  title: "Components/${NAME}",
  component: ${NAME},
};
export default meta;

type Story = StoryObj<${NAME}Props>;

export const Default: Story = {
  args: {
    label: "${NAME}",
    onAction: fn(),
  },
};

// Add Empty / Loading / Error states as their own stories using the same shared fixtures.
EOF

cat > "$TEST" <<EOF
import { describe, expect, it, vi } from "vitest";
import { ${NAME} } from "./${NAME}";
import { renderWithProviders, screen } from "@/test/utils";

describe("${NAME}", () => {
  it("renders its label", () => {
    renderWithProviders(<${NAME} label="hello" onAction={() => {}} />);
    expect(screen.getByRole("button", { name: "hello" })).toBeInTheDocument();
  });

  it("calls onAction when activated", async () => {
    const onAction = vi.fn();
    renderWithProviders(<${NAME} label="go" onAction={onAction} />);
    screen.getByRole("button", { name: "go" }).click();
    expect(onAction).toHaveBeenCalledOnce();
  });
});
EOF

printf 'Created trio in %s:\n  %s\n  %s\n  %s\n' "$DIR" "$NAME.tsx" "$NAME.stories.tsx" "$NAME.test.tsx"
