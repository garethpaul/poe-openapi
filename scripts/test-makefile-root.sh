#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
ATTACKER_ROOT=/tmp/poe-openapi-attacker-root
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/poe-openapi-root-control-XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset MAKEFILES MAKEFILE_LIST

CONTROL_DIR="$TEMP_ROOT/control"
BACKTICK_MARKER="$CONTROL_DIR/POE_OPENAPI_BACKTICK_MARKER"
RUBY_MARKER="$CONTROL_DIR/POE_OPENAPI_RUBY_MARKER"
ATTACKER_MAKEFILE="$TEMP_ROOT/attacker/Makefile"
CHECKOUT="$TEMP_ROOT/Poe OpenAPI's [gate] \"quoted\" \`touch POE_OPENAPI_BACKTICK_MARKER\` ; wildcard* #hash percent% colon: "
COMMAND_LOG="$TEMP_ROOT/commands.log"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
MAKEFILE="$CHECKOUT/Makefile"
mkdir "$CONTROL_DIR" "$CHECKOUT" "$(dirname -- "$ATTACKER_MAKEFILE")"
: >"$ATTACKER_MAKEFILE"
CHECKOUT=$(CDPATH= cd -- "$CHECKOUT" && pwd -P)
MAKEFILE="$CHECKOUT/Makefile"
mkdir "$CHECKOUT/scripts"
cp "$ROOT_DIR/Makefile" "$MAKEFILE"

write_logger() {
  file=$1
  cat >"$file" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "$PWD" "$*" >> "$POE_OPENAPI_COMMAND_LOG"
EOF
  chmod +x "$file"
}

write_ruby_logger() {
  file=$1
  cat >"$file" <<'EOF'
#!/usr/bin/env ruby
File.open(ENV.fetch('POE_OPENAPI_COMMAND_LOG'), 'a') do |log|
  log.puts "#{Dir.pwd}|#{ARGV.join(' ')}"
end
EOF
  chmod +x "$file"
}

for script in \
  check-baseline.sh \
  test-validator.sh \
  test-generator.sh \
  test-makefile-root.sh; do
  write_logger "$CHECKOUT/scripts/$script"
done
for script in generate-spec-md.rb validate-openapi.rb; do
  write_ruby_logger "$CHECKOUT/scripts/$script"
done

FAKE_RUBY="$TEMP_ROOT/fake-ruby"
cat >"$FAKE_RUBY" <<'EOF'
#!/bin/sh
: >"$POE_OPENAPI_RUBY_MARKER"
printf '%s|%s\n' "$PWD" "$*" >> "$POE_OPENAPI_COMMAND_LOG"
EOF
chmod +x "$FAKE_RUBY"

FAKE_SHELL="$TEMP_ROOT/fake-shell"
cat >"$FAKE_SHELL" <<EOF
#!/bin/sh
printf '%s\n' invoked >> '$FAKE_SHELL_LOG'
exec /bin/sh "\$@"
EOF
chmod +x "$FAKE_SHELL"

assert_commands_stayed_in_checkout() {
  scenario=$1
  target=$2
  if [ ! -s "$COMMAND_LOG" ]; then
    printf '%s\n' "$scenario $target executed no quality command" >&2
    exit 1
  fi
  while IFS= read -r command; do
    case "$command" in
      "$CHECKOUT|"*) ;;
      *)
        printf '%s\n' "$scenario $target escaped the checkout: $command" >&2
        exit 1
        ;;
    esac
  done <"$COMMAND_LOG"
}

run_case() {
  scenario=$1
  target=$2
  mode=$3
  rm -f "$COMMAND_LOG"
  output="$TEMP_ROOT/output"
  set +e
  case "$mode" in
    default)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-root)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "REPO_ROOT=$ATTACKER_ROOT" "$target") >"$output" 2>&1
      ;;
    environment-root)
      (cd "$CONTROL_DIR" && REPO_ROOT="$ATTACKER_ROOT" POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-makefile)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "REPOSITORY_MAKEFILE=$ATTACKER_MAKEFILE" "$target") >"$output" 2>&1
      ;;
    environment-makefile)
      (cd "$CONTROL_DIR" && REPOSITORY_MAKEFILE="$ATTACKER_MAKEFILE" POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-shell)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "SHELL=$FAKE_SHELL" "$target") >"$output" 2>&1
      ;;
    environment-shell)
      (cd "$CONTROL_DIR" && SHELL="$FAKE_SHELL" POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-flags)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" '.SHELLFLAGS=-x -c' "$target") >"$output" 2>&1
      ;;
    environment-flags)
      (cd "$CONTROL_DIR" && env '.SHELLFLAGS=-x -c' POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-ruby)
      (cd "$CONTROL_DIR" && POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "RUBY=$FAKE_RUBY" "$target") >"$output" 2>&1
      ;;
    environment-ruby)
      (cd "$CONTROL_DIR" && RUBY="$FAKE_RUBY" POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" POE_OPENAPI_RUBY_MARKER="$RUBY_MARKER" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    *)
      printf '%s\n' "unknown test mode: $mode" >&2
      exit 1
      ;;
  esac
  result=$?
  set -e
  if [ "$result" -ne 0 ]; then
    printf '%s\n' "$scenario $target failed" >&2
    cat "$output" >&2
    exit 1
  fi
  case "$scenario" in
    command-flags|environment-flags)
      if grep -Fq '+ makefile=' "$output"; then
        printf '%s\n' "$scenario $target accepted caller-controlled shell flags" >&2
        exit 1
      fi
      ;;
  esac
  assert_commands_stayed_in_checkout "$scenario" "$target"
}

for target in build check generate lint root-test test verify; do
  run_case default "$target" default
  run_case command-root "$target" command-root
  run_case environment-root "$target" environment-root
  run_case command-makefile "$target" command-makefile
  run_case environment-makefile "$target" environment-makefile
  run_case command-shell "$target" command-shell
  run_case environment-shell "$target" environment-shell
  run_case command-flags "$target" command-flags
  run_case environment-flags "$target" environment-flags
  run_case command-ruby "$target" command-ruby
  run_case environment-ruby "$target" environment-ruby
done

if [ -e "$BACKTICK_MARKER" ]; then
  printf '%s\n' "checkout-path backticks executed a command" >&2
  exit 1
fi
if [ -e "$FAKE_SHELL_LOG" ]; then
  printf '%s\n' "caller-controlled SHELL was executed" >&2
  exit 1
fi
if [ -e "$RUBY_MARKER" ]; then
  printf '%s\n' "caller-controlled RUBY was executed" >&2
  exit 1
fi

if (cd "$CONTROL_DIR" && make --no-print-directory --file "$MAKEFILE" MAKEFILE_LIST=/tmp/untrusted check) >"$TEMP_ROOT/command-list.out" 2>&1; then
  printf '%s\n' "command MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/command-list.out"

if (cd "$CONTROL_DIR" && MAKEFILE_LIST=/tmp/untrusted make --environment-overrides --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/environment-list.out" 2>&1; then
  printf '%s\n' "environment MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/environment-list.out"

PRELOADED_MAKEFILE="$TEMP_ROOT/preloaded.mk"
printf '%s\n' 'REPO_ROOT := /tmp/preloaded-attacker-root' >"$PRELOADED_MAKEFILE"
rm -f "$COMMAND_LOG"
if (cd "$CONTROL_DIR" && MAKEFILES="$PRELOADED_MAKEFILE" POE_OPENAPI_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/preloaded.out" 2>&1; then
  printf '%s\n' "MAKEFILES preload unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILES must be empty" "$TEMP_ROOT/preloaded.out"
if [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "MAKEFILES preload reached a quality command" >&2
  exit 1
fi

printf '%s\n' "Makefile root tests passed: 77 executed target/authority cases, 2 MAKEFILE_LIST rejections, and 1 detected MAKEFILES preload rejection"
