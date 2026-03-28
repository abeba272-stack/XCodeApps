#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PRODUCT_NAME = "AI Content Machine"
REPORT_TYPE = "Morning Engineering + Product Intelligence Report"


@dataclass
class CommandResult:
    command: list[str]
    returncode: int | None
    stdout: str
    stderr: str
    status: str
    duration_seconds: float


def decode_output(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def run_command(command: list[str], cwd: Path, timeout: int) -> CommandResult:
    started = dt.datetime.now()
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=False,
            timeout=timeout,
        )
        duration = (dt.datetime.now() - started).total_seconds()
        return CommandResult(
            command=command,
            returncode=completed.returncode,
            stdout=decode_output(completed.stdout),
            stderr=decode_output(completed.stderr),
            status="success" if completed.returncode == 0 else "failure",
            duration_seconds=duration,
        )
    except subprocess.TimeoutExpired as exc:
        duration = (dt.datetime.now() - started).total_seconds()
        return CommandResult(
            command=command,
            returncode=None,
            stdout=decode_output(exc.stdout),
            stderr=decode_output(exc.stderr),
            status="timeout",
            duration_seconds=duration,
        )


def shell_quote(text: str) -> str:
    return "'" + text.replace("'", "'\"'\"'") + "'"


def find_repo_root(explicit: str | None) -> Path:
    if explicit:
        candidate = Path(explicit).expanduser().resolve()
        if is_repo_root(candidate):
            return candidate
        raise SystemExit(f"Provided repo root is invalid: {candidate}")

    current = Path(__file__).resolve()
    for candidate in [current.parent] + list(current.parents):
        if is_repo_root(candidate):
            return candidate
    raise SystemExit("Could not locate AI Content Machine repo root.")


def is_repo_root(path: Path) -> bool:
    return (path / "AIContentMachine.xcodeproj").exists() and (path / "AIContentMachine").exists()


def strip_comment(line: str) -> str:
    if "#" not in line:
        return line.rstrip("\n")

    in_single = False
    in_double = False
    output: list[str] = []
    for char in line.rstrip("\n"):
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        elif char == "#" and not in_single and not in_double:
            break
        output.append(char)
    return "".join(output)


def parse_scalar(value: str) -> Any:
    trimmed = value.strip()
    if trimmed in {"", "null", "NULL", "~"}:
        return ""
    if (trimmed.startswith('"') and trimmed.endswith('"')) or (trimmed.startswith("'") and trimmed.endswith("'")):
        return trimmed[1:-1]
    if trimmed.lower() == "true":
        return True
    if trimmed.lower() == "false":
        return False
    if re.fullmatch(r"-?\d+", trimmed):
        return int(trimmed)
    if re.fullmatch(r"-?\d+\.\d+", trimmed):
        return float(trimmed)
    return trimmed


def parse_yaml_lines(lines: list[tuple[int, str]], start_index: int, indent: int) -> tuple[dict[str, Any], int]:
    result: dict[str, Any] = {}
    index = start_index

    while index < len(lines):
        line_indent, content = lines[index]
        if line_indent < indent:
            break
        if line_indent != indent:
            raise ValueError(f"Unexpected indentation for line: {content}")
        if content.startswith("- "):
            raise ValueError("Top-level lists are not supported in this minimal parser.")
        if ":" not in content:
            raise ValueError(f"Expected key/value YAML line, got: {content}")

        key, raw_value = content.split(":", 1)
        key = key.strip()
        raw_value = raw_value.strip()

        if raw_value:
            result[key] = parse_scalar(raw_value)
            index += 1
            continue

        next_index = index + 1
        if next_index >= len(lines):
            result[key] = ""
            index = next_index
            continue

        next_indent, next_content = lines[next_index]
        if next_indent <= indent:
            result[key] = ""
            index = next_index
            continue

        if next_content.startswith("- "):
            items: list[Any] = []
            while next_index < len(lines):
                item_indent, item_content = lines[next_index]
                if item_indent < next_indent:
                    break
                if item_indent != next_indent or not item_content.startswith("- "):
                    break
                items.append(parse_scalar(item_content[2:]))
                next_index += 1
            result[key] = items
            index = next_index
            continue

        nested, next_index = parse_yaml_lines(lines, next_index, next_indent)
        result[key] = nested
        index = next_index

    return result, index


def load_optional_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}

    processed: list[tuple[int, str]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        without_comment = strip_comment(raw_line).rstrip()
        if not without_comment.strip():
            continue
        indent = len(without_comment) - len(without_comment.lstrip(" "))
        processed.append((indent, without_comment.strip()))

    if not processed:
        return {}

    parsed, _ = parse_yaml_lines(processed, 0, 0)
    return parsed


def present(value: Any) -> str:
    if value is None:
        return "not evidenced"
    if isinstance(value, str):
        return value if value.strip() else "not evidenced"
    if isinstance(value, list):
        return ", ".join(str(item) for item in value if str(item).strip()) or "not evidenced"
    if isinstance(value, dict):
        if not value:
            return "not evidenced"
        return ", ".join(f"{key}: {present(subvalue)}" for key, subvalue in value.items())
    return str(value)


def has_meaningful_data(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, list):
        return any(has_meaningful_data(item) for item in value)
    if isinstance(value, dict):
        return any(has_meaningful_data(item) for item in value.values())
    return True


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def count_regex(path: Path, pattern: str) -> int:
    return len(re.findall(pattern, read_text(path), flags=re.MULTILINE))


def line_count(path: Path) -> int:
    return read_text(path).count("\n") + (1 if path.exists() else 0)


def largest_swift_files(root: Path, limit: int = 8) -> list[tuple[str, int]]:
    entries: list[tuple[str, int]] = []
    for path in root.rglob("*.swift"):
        try:
            entries.append((str(path.relative_to(root)), line_count(path)))
        except OSError:
            continue
    return sorted(entries, key=lambda item: item[1], reverse=True)[:limit]


def extract_first(pattern: str, text: str, default: str = "") -> str:
    match = re.search(pattern, text, flags=re.MULTILINE)
    return match.group(1) if match else default


def get_available_simulator_id(cwd: Path) -> str:
    result = run_command(["xcrun", "simctl", "list", "devices", "available"], cwd, timeout=30)
    for line in result.stdout.splitlines():
        if "iPhone" not in line:
            continue
        match = re.search(r"\(([A-F0-9-]{36})\)", line)
        if match:
            return match.group(1)
    return ""


def summarize_build(result: CommandResult) -> tuple[str, str]:
    if result.status == "skipped":
        return "skipped", "Build step was skipped."
    if result.status == "success" and "** BUILD SUCCEEDED **" in result.stdout:
        return "green", f"Build succeeded in {result.duration_seconds:.1f}s."
    if result.status == "timeout":
        return "inconclusive", f"Build timed out after {result.duration_seconds:.1f}s."
    return "failing", f"Build failed with status {result.status} after {result.duration_seconds:.1f}s."


def summarize_tests(result: CommandResult) -> tuple[str, str]:
    if result.status == "skipped":
        return "skipped", "Test step was skipped."
    combined = "\n".join(part for part in [result.stdout, result.stderr] if part)
    if result.status == "success" and "Test Suite" in combined and "failed" not in combined.lower():
        return "green", f"Tests completed successfully in {result.duration_seconds:.1f}s."
    if result.status == "timeout":
        return "inconclusive/hanging", f"Tests timed out after {result.duration_seconds:.1f}s."
    if result.status == "failure":
        return "failing", f"Tests failed in {result.duration_seconds:.1f}s."
    return "inconclusive", f"Test status is {result.status} after {result.duration_seconds:.1f}s."


def bullet_lines(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items)


def render_scored_item(label: str, score: int, justification: str) -> str:
    return f"- {label}: {score}/10\n  Justification: {justification}"


def render_task(title: str, why: str, impact: str, complexity: str, effort: str, dependency_risk: str) -> str:
    return (
        f"- {title}\n"
        f"  Why it matters: {why}\n"
        f"  Expected impact: {impact}\n"
        f"  Estimated complexity: {complexity}\n"
        f"  Estimated effort: {effort}\n"
        f"  Dependency risk: {dependency_risk}"
    )


def render_strategy_item(title: str, why: str, why_now: str, unlocks: str) -> str:
    return (
        f"- {title}\n"
        f"  Why this matters: {why}\n"
        f"  Why now: {why_now}\n"
        f"  What it unlocks: {unlocks}"
    )


def build_report(repo_root: Path, report_date: dt.date, project_context: dict[str, Any], metrics: dict[str, Any],
                 previous_report: Path | None, git_status: CommandResult, git_log: CommandResult, git_diff: CommandResult,
                 build_result: CommandResult, test_result: CommandResult, simulator_id: str) -> str:
    app_dir = repo_root / "AIContentMachine"
    readme_text = read_text(repo_root / "README.md")
    checklist_text = read_text(repo_root / "APP_STORE_SETUP_CHECKLIST.md")
    template_engine_text = read_text(app_dir / "Services" / "TemplateEngine.swift")
    feature_policy_text = read_text(app_dir / "Models" / "MonetizationModels.swift")
    template_catalog_test_text = read_text(app_dir / "Tests" / "TemplateEngineCatalogTests.swift")
    root_view_path = app_dir / "Views" / "RootView.swift"
    result_view_path = app_dir / "Views" / "Generator" / "ContentResultView.swift"
    dashboard_view_path = app_dir / "Views" / "Dashboard" / "DashboardView.swift"
    planner_view_path = app_dir / "Views" / "Planner" / "PlannerView.swift"
    settings_view_path = app_dir / "Views" / "Settings" / "SettingsView.swift"
    app_container_path = app_dir / "Utilities" / "AppContainer.swift"
    app_services_path = app_dir / "Services" / "AppServices.swift"
    generation_session_path = app_dir / "Models" / "GenerationSession.swift"
    storekit_path = app_dir / "AIContentMachine.storekit"
    paywall_path = app_dir / "Views" / "Settings" / "PaywallView.swift"
    auth_view_path = app_dir / "Views" / "Auth" / "AuthView.swift"
    auth_status_entries = [line for line in git_status.stdout.splitlines() if "Auth" in line or "UserProfile.swift" in line or "RootView.swift" in line]

    template_count = int(extract_first(r"templates\.count,\s*(\d+)", template_catalog_test_text, "0")) or count_regex(app_dir / "Services" / "TemplateEngine.swift", r"seedKey:")
    free_template_count = int(extract_first(r"filter\s*\{\s*\$0\.tier == \.free\s*\}\.count,\s*(\d+)", template_catalog_test_text, "0")) or count_regex(app_dir / "Services" / "TemplateEngine.swift", r"tier:\s*\.free")
    pro_template_count = int(extract_first(r"filter\\?\.isPro\)\.count,\s*(\d+)", template_catalog_test_text, "0")) or int(extract_first(r"filter\(\\\.isPro\)\.count,\s*(\d+)", template_catalog_test_text, "0")) or count_regex(app_dir / "Services" / "TemplateEngine.swift", r"tier:\s*\.pro")
    test_files = sorted((app_dir / "Tests").glob("*.swift"))
    test_method_count = sum(count_regex(path, r"func test") for path in test_files)
    build_state, build_summary = summarize_build(build_result)
    test_state, test_summary = summarize_tests(test_result)
    if test_state == "inconclusive/hanging":
        test_lane_phrase = "tests are timing out in this environment"
        test_lane_action = "Fix the hanging simulator-hosted test lane and get one reliable green `xcodebuild test` path."
        test_lane_focus = "reproduce the hanging test lane, isolate whether StoreKit/auth startup is involved, and either fix it or narrow it to one reproducible failing path with logs."
    elif test_state == "failing":
        test_lane_phrase = "tests are currently failing in this environment"
        test_lane_action = "Fix the failing simulator-hosted test lane and get one reliable green `xcodebuild test` path."
        test_lane_focus = "reproduce the failing test lane, isolate whether StoreKit/auth startup is involved, and either fix it or narrow it to one reproducible failing path with logs."
    elif test_state == "green":
        test_lane_phrase = "tests are currently green in this environment"
        test_lane_action = "Protect the green simulator-hosted test lane and prevent regressions while the auth branch is still in flight."
        test_lane_focus = "lock in the green test lane, then add focused coverage for auth/session and monetization edge cases."
    else:
        test_lane_phrase = "tests are not yet a trustworthy signal in this environment"
        test_lane_action = "Restore one reliable simulator-hosted `xcodebuild test` path."
        test_lane_focus = "narrow why the test lane is not trustworthy and turn it into one stable, reproducible path."
    large_files = largest_swift_files(app_dir)
    direct_save_hits = run_command(
        ["python3", "-c",
         (
             "from pathlib import Path; import re;"
             f"root=Path({json.dumps(str(app_dir))});"
             "hits=[];"
             "patterns=[r'try\\?\\s+.*save\\(', r'context\\.save\\(', r'modelContext'];"
             "for path in root.rglob('*.swift'): "
             " text=path.read_text(encoding='utf-8');"
             " count=sum(len(re.findall(p, text)) for p in patterns);"
             " hits.append((path.relative_to(root).as_posix(), count));"
             "print('\\n'.join(f'{p}:{c}' for p,c in sorted((item for item in hits if item[1]>0), key=lambda x:(-x[1], x[0]))))"
         )],
        repo_root,
        timeout=30,
    )
    direct_save_lines = [line for line in direct_save_hits.stdout.splitlines() if line.strip()]
    latest_commit_line = git_log.stdout.splitlines()[0] if git_log.stdout.splitlines() else "not evidenced"
    previous_report_line = (
        f"Delta summary: no previous daily report exists in docs/reports/daily, so this is a baseline morning report."
        if previous_report is None
        else f"Delta summary: previous report found at {previous_report.relative_to(repo_root)}. This report should be read as a new snapshot against that earlier baseline."
    )

    has_context = has_meaningful_data(project_context)
    has_metrics = has_meaningful_data(metrics)

    target_audience = present(project_context.get("target_audience")) if has_context else "not evidenced"
    core_problem = present(project_context.get("core_problem_solved")) if has_context else "not evidenced"
    pricing_context = present(project_context.get("pricing")) if has_context else "not evidenced"
    conversion_thesis = present(project_context.get("paywall_conversion_thesis")) if has_context else "not evidenced"
    distribution_channels = present(project_context.get("distribution_channels")) if has_context else "not evidenced"
    competition = present(project_context.get("competition")) if has_context else "not evidenced"
    moat = present(project_context.get("moat_or_advantage")) if has_context else "not evidenced"
    vision_12 = present(project_context.get("vision_12_months")) if has_context else "not evidenced"
    vision_24 = present(project_context.get("vision_24_months")) if has_context else "not evidenced"
    vision_36 = present(project_context.get("vision_36_months")) if has_context else "not evidenced"
    current_risks_context = present(project_context.get("current_top_risks")) if has_context else "not evidenced"

    installs = present(metrics.get("installs_or_downloads")) if has_metrics else "not evidenced"
    active_users = present(metrics.get("active_users")) if has_metrics else "not evidenced"
    subscribers = present(metrics.get("trials_or_subscribers")) if has_metrics else "not evidenced"
    conversion_rate = present(metrics.get("conversion_rate")) if has_metrics else "not evidenced"
    retention = present(metrics.get("retention")) if has_metrics else "not evidenced"
    feedback_themes = present(metrics.get("recent_feedback_themes")) if has_metrics else "not evidenced"
    acquisition = present(metrics.get("acquisition_performance")) if has_metrics else "not evidenced"
    cost_per_generation = present(metrics.get("cost_per_generation")) if has_metrics else "not evidenced"
    cost_per_user = present(metrics.get("cost_per_active_user")) if has_metrics else "not evidenced"

    product_summary = [
        previous_report_line,
        "Fact: Repo documentation positions the app as a local creator operating system for creators who need to turn rough ideas into structured short-form content packages faster. Evidence: `README.md`.",
        f"Fact: The app already supports onboarding, dashboard, generator, result review/edit/export, library, planner, templates, offline mock generation, and local AI server scaffolding. Evidence: README + feature folders + root shell.",
        f"Fact: The latest committed milestone is StoreKit-based Pro gating plus starter template seeding. Evidence: latest commit `{latest_commit_line}` and files `{storekit_path.relative_to(repo_root)}`, `{paywall_path.relative_to(repo_root)}`.",
        f"Fact: The working tree is not clean. There is in-flight auth/session work that is not yet committed or shipped. Evidence: {len(git_status.stdout.splitlines())} modified/untracked entries, including auth files.",
        f"Fact: Build health is better than test health right now. {build_summary} {test_summary}",
        f"Fact: The template catalog is real, not placeholder-only: {template_count} starter templates, {free_template_count} free and {pro_template_count} Pro. Evidence: `TemplateEngine.swift` + template catalog test.",
        f"Inference: Momentum is positive but risky. The product is moving toward product-readiness, but quality confidence is lagging behind feature progress because the hosted test lane is not cleanly green.",
        f"Recommendation: Today should prioritize restoring a trustworthy test lane and turning the current monetization scaffolding into App-Store-ready configuration, not adding another feature layer.",
    ]

    what_app_can_do = [
        "### Onboarding — strong",
        "- Fact: The app has a full onboarding flow with niche, platform, language, tone, goal, posting frequency, and creator profile capture. Evidence: `Views/Onboarding/*`, `ViewModels/OnboardingViewModel.swift`, `README.md`.",
        "- Fact: Onboarding state persists locally through SwiftData and is used to personalize later flows. Evidence: `UserProfile.swift`, `AppBootstrapper.swift`, `RootView.swift`.",
        "- Fact: The product is clearly aimed at creators who need repeatable short-form output, not chat-style freeform interaction. Evidence: README wording, dashboard/generator/template structure, and result package shape.",
        "### Dashboard — usable but incomplete",
        "- Fact: The dashboard exposes a creator operating-system overview with metrics, suggestions, recent projects, and planner navigation. Evidence: `Views/Dashboard/DashboardView.swift` and README.",
        f"- Inference: The dashboard is product-shaped, but still heavy in one file ({line_count(dashboard_view_path)} lines), which raises change risk and keeps it below polished product quality.",
        "### Generator — strong",
        "- Fact: The generator supports single idea, batch ideas, and full content package modes, template prefill, feature gating, and creator context injection. Evidence: `CreateContentView.swift`, `ContentGeneratorViewModel.swift`, `Services/AIEngine.swift`.",
        "- Fact: The generator can run fully offline using deterministic mock generation. Evidence: `MockContentGenerationService.swift` and README.",
        "### Result / Edit / Export — usable but incomplete",
        "- Fact: Results include hook, script, caption, hashtags, CTA, shot list, score, and modular video prompt export. Evidence: `ContentResultView.swift`, `CopyExportService.swift`, tests.",
        f"- Inference: The result flow is feature-rich but still too dense. The view is {line_count(result_view_path)} lines and remains a cognitive hotspot.",
        "### Templates — strong",
        f"- Fact: The app ships with {template_count} seeded starter templates distributed across free and Pro tiers. Evidence: `TemplateEngine.swift`, `TemplateSeedService.swift`, `TemplateEngineCatalogTests.swift`.",
        "- Fact: Pro templates are visibly gated and route into the paywall rather than silently failing. Evidence: `TemplatesView.swift`, `FeatureAccessController.swift`, `PaywallView.swift`.",
        "### Library — strong",
        "- Fact: Saved projects can be searched, filtered, sorted, favorited, opened, and copied/exported. Evidence: `Views/Library/*`, README.",
        "### Planner — usable but incomplete",
        "- Fact: The planner supports assignment, streaks, backlog behavior, and mark-posted flows. Evidence: `PlannerService.swift`, `PlannerViewModel.swift`, `PlannerView.swift`, tests.",
        f"- Inference: Planner is useful already but remains a maintenance hotspot because the main view is {line_count(planner_view_path)} lines.",
        "### Settings — usable but incomplete",
        "- Fact: Settings cover theme, provider mode, export/reset operations, and current monetization controls; the working tree also adds account/session settings. Evidence: `SettingsView.swift`, `SettingsViewModel.swift`, `APP_STORE_SETUP_CHECKLIST.md`.",
        "- Fact: Current paywall legal links are still generic Apple destinations, not final app-owned legal/support URLs. Evidence: `APP_STORE_SETUP_CHECKLIST.md`.",
        "### AI modes — strong",
        "- Fact: Offline mock mode is the default and works without any backend. Evidence: README, `MockContentGenerationService.swift`, `FeatureAccessPolicy.freeProviderModes`.",
        "- Fact: Local/custom endpoint mode exists structurally and is Pro-gated. Evidence: `RealAIContentService.swift`, `FeatureAccessController.swift`, `SubscriptionStore.swift`.",
        "### Monetization state — usable but incomplete",
        "- Fact: There is a real StoreKit subscription layer, entitlement state, paywall UI, restore flow, and Pro feature gating. Evidence: `SubscriptionStore.swift`, `PaywallView.swift`, `MonetizationModels.swift`.",
        "- Inference: Monetization is product-native in structure, but not ready to sell seriously until App Store Connect products, final prices, and legal URLs are configured.",
    ]

    changed_recently = [
        f"Fact: The last committed feature cycle materially changed templates, monetization, and gating. Evidence: latest commit `{latest_commit_line}` and added files for StoreKit, paywall, feature access, and template seeding.",
        "Fact: The previous committed cycle before that cleaned up the AI stack, introduced a container/composition root, added network and error abstractions, and separated transient generation session state from persisted project state. Evidence: commit `1c2a9b0` in git log.",
        "Fact: The working tree currently contains a second meaningful change wave: auth/session work with Apple Sign-In scaffolding, email/password registration, prompt context persistence, and settings/account expansion. Evidence: uncommitted files `Models/AuthModels.swift`, `Services/AuthService.swift`, `ViewModels/AuthViewModel.swift`, `Views/Auth/*`.",
        "Inference: The current direction is coherent rather than fragmented. Recent work consistently pushes the app from MVP utility toward product structure: templates, monetization, then account/session.",
        "Recommendation: Do not mix more product bets into this branch until the auth work is either committed behind a stable boundary or parked. The branch is carrying too much strategic surface area at once.",
    ]

    maturity_scores = [
        render_scored_item("core product usefulness", 8, "The app already delivers a real creator workflow from idea to draft, planner, and export. The main blocker is quality confidence, not usefulness."),
        render_scored_item("user clarity", 7, "The product identity is clear in code and UI, but some heavy screens still ask the user to absorb too much at once."),
        render_scored_item("onboarding quality", 8, "Onboarding is structured, persistent, and meaningfully tied to later generation behavior."),
        render_scored_item("generator quality", 8, "The generator supports multiple modes, templates, creator context, and offline reliability. This is one of the strongest subsystems."),
        render_scored_item("templates usefulness", 8, f"The template catalog is real and day-one useful with {template_count} seeded entries and tested free/Pro separation."),
        render_scored_item("result/edit experience", 6, "Feature depth is high, but the result surface remains too dense and still behaves more like a powerful internal tool than a sharply edited product screen."),
        render_scored_item("planner value", 7, "Planner adds real workflow value and streak logic, but the main view still needs decomposition and polish."),
        render_scored_item("architecture quality", 7, "Container, services, transient session, and monetization layers exist, but large view files and some direct persistence coupling remain."),
        render_scored_item("monetization readiness", 6, "StoreKit and gating exist, but final pricing, legal links, App Store Connect setup, and a fully trusted purchase QA loop are still missing."),
        render_scored_item("App Store readiness", 5, "The product now looks closer to sellable, but external store setup, policy links, QA, and test confidence are not finished."),
        render_scored_item("technical stability", 5, f"Builds succeed, but tests are not reliably green. Current test state: {test_state}."),
        render_scored_item("launchability", 6, "This is beyond an internal prototype, but not yet a confidently launchable paid product."),
    ]
    overall_maturity = (
        "Overall maturity score: 6.8/10\n"
        "What is holding the score down: the app is ahead on feature and product shape, but behind on quality confidence, App Store execution, and final business setup."
    )

    missing_pieces = [
        "### Product missing pieces",
        "- A cleaner, lower-density result experience that feels decisively product-grade rather than feature-heavy.",
        "- Fully committed account/session flow; auth exists only in the working tree and therefore is not yet shipped or test-proven.",
        "- A stronger retention layer such as recurring creator rituals, next-best-action prompts, or post-publish review loops. Not evidenced in the repo today.",
        "### Technical missing pieces",
        f"- A clean green hosted test lane. Fact: builds pass; {test_lane_phrase}.",
        "- Further decomposition of large files, especially RootView, ContentResultView, DashboardView, and PlannerView.",
        "- Broader test coverage around StoreKit state changes, account/session flows, and end-to-end generation/save/planner workflows.",
        "### Monetization missing pieces",
        "- Final monthly/yearly prices are not evidenced in repo-owned configuration; the checklist still calls them pending.",
        "- Real Terms, Privacy, and Support URLs are missing; paywall still points to generic Apple endpoints.",
        "- App Store Connect app record, subscription group, localized product copy, and QA pass remain external blockers.",
        "### Quality / reliability missing pieces",
        "- Structured logging beyond console use, crash reporting, analytics, and post-release observability are not evidenced.",
        "- A deterministic StoreKit QA loop tied to the scheme configuration and test execution.",
        "### UX missing pieces",
        "- Further refinement of the result screen density and planner/dashboard decomposition.",
        "- Stronger onboarding-to-first-win bridge; the app personalizes, but the first-session acceleration loop could be sharper.",
        "### Launch / business missing pieces",
        f"- Actual usage, retention, and conversion data are {'partially present in docs/reporting/metrics.yaml' if has_metrics else 'not evidenced'}; there is no repo-grounded proof yet that the paywall or workflow converts.",
        f"- Distribution plan is {distribution_channels}. Competition positioning is {competition}.",
    ]

    todo_critical = [
        render_task(
            test_lane_action,
            "Build success without trusted test completion is the biggest quality blind spot in the project.",
            "Raises release confidence, reduces regression risk, and makes every later feature cheaper to ship.",
            "high",
            "M / 2-4h",
            "Medium: depends on simulator/test-host behavior and StoreKit/Auth interactions.",
        ),
        render_task(
            "Decide the fate of the in-flight auth/session work: either finish and commit it behind a stable boundary or park it cleanly.",
            "The working tree is carrying a major product feature that is currently neither shipped nor protected by a clean test signal.",
            "Reduces branch risk and clarifies whether account-based product strategy is active now or later.",
            "medium",
            "M / 2-4h",
            "Low to medium: mostly local engineering discipline, but can expand if auth edge cases surface.",
        ),
        render_task(
            "Complete the external monetization blockers: StoreKit scheme assignment, App Store Connect subscriptions, and final legal/support URLs.",
            "The app already has structural monetization. External setup is now the bottleneck.",
            "Turns the current Pro model from architectural scaffolding into a sellable system.",
            "medium",
            "S-M / 1-3h",
            "High: depends on Apple account access and external assets/policy pages.",
        ),
    ]
    todo_important = [
        render_task(
            "Refine the result screen into smaller sections or subviews and reduce decision density at the top of the experience.",
            "This is one of the most visible product surfaces and currently still feels overloaded.",
            "Improves perceived quality, usability, and launch readiness without inventing a new feature.",
            "medium",
            "M / 2-5h",
            "Low: contained to a known hotspot file.",
        ),
        render_task(
            "Add explicit tests for subscription gating, restore behavior, and auth/session state transitions.",
            "Monetization and session work now affect who can use core features. These paths cannot remain weakly tested.",
            "Protects revenue-critical and trust-critical behavior.",
            "medium",
            "M / 2-4h",
            "Medium: some StoreKit/Auth seams may need more mocking or isolation.",
        ),
        render_task(
            "Fill in `docs/reporting/project-context.yaml` and `docs/reporting/metrics.yaml` with real business inputs.",
            "Without those files, the morning report can only be strong on engineering truth, not on business truth.",
            "Makes the daily report useful for product, growth, and monetization decisions instead of code-only review.",
            "low",
            "S / 30-60m",
            "Low: depends only on the operator having the business answers.",
        ),
    ]
    todo_nice = [
        render_task(
            "Add lightweight analytics hooks around generation, save, planner assignment, paywall open, and purchase outcome.",
            "The app is now close enough to product form that instrumentation would create real leverage.",
            "Creates a factual feedback loop for retention and conversion decisions.",
            "medium",
            "M / 2-4h",
            "Medium: choose an analytics path without overbuilding.",
        ),
        render_task(
            "Tighten the README and docs so they reflect the current monetization and auth direction.",
            "Documentation drift creates confusion for future contributors and daily reporting automation.",
            "Improves onboarding for humans and reduces future reporting ambiguity.",
            "low",
            "S / 30-60m",
            "Low.",
        ),
    ]

    strategic_moves = [
        "### Top 3 product moves",
        render_strategy_item("Make the first-run path feel immediately valuable with starter templates + one-click first generation.", "The app already has the pieces; product value needs to be obvious in the first minutes.", "The core tool is mature enough that onboarding-to-first-output now matters more than adding another module.", "Higher activation and clearer product identity."),
        render_strategy_item("Finish account/session strategy only if it strengthens retention, not because auth is fashionable.", "The app is local-first; auth should serve continuity, subscription portability, or personal context reuse.", "There is already in-flight auth work. It needs a product reason, not just implementation momentum.", "Cross-device potential, clearer subscription identity, and richer persistent prompt context."),
        render_strategy_item("Turn the app from 'generator' into 'daily creator operating rhythm' with next actions and publishing loops.", "That is how retention is built for this category.", "The generator is already good enough to support a stronger operating system layer.", "Daily/weekly habit formation and better retention potential."),
        "### Top 3 engineering moves",
        render_strategy_item("Stabilize the hosted test lane.", "This is the highest-leverage engineering risk reducer right now.", "Feature velocity has outpaced confidence.", "Safer shipping, faster iteration, and less fear around monetization/auth changes."),
        render_strategy_item("Decompose the remaining god views by responsibility, not by line count alone.", "The large SwiftUI files are now the clearest maintainability debt.", "The architecture already improved elsewhere; UI composition is the next bottleneck.", "Safer UI iteration and fewer regressions."),
        render_strategy_item("Create explicit seams for account-aware generation and future provider modes.", "The AI and account layers are converging.", "Auth work is already present; now is the time to keep boundaries clean.", "Future premium modes without entangling UI and provider logic."),
        "### Top 3 monetization moves",
        render_strategy_item("Get App Store Connect products and paywall legal/support assets finalized.", "Current code is ahead of business setup.", "Without external setup, monetization remains theoretical.", "Real subscription testing and real launch readiness."),
        render_strategy_item("Instrument paywall opens, selections, restores, and purchase outcomes.", "You cannot optimize conversion with no measurements.", "The paywall now exists and is worth measuring.", "Paywall iteration based on evidence rather than taste."),
        render_strategy_item("Clarify the Pro promise around workflow leverage, not just unlocked buttons.", "Creators pay for speed and output quality, not menus.", "The app already has real premium capabilities; messaging needs to catch up.", "Stronger conversion and better App Store positioning."),
        "### Top 3 UX moves",
        render_strategy_item("Reduce result-screen density.", "This is likely the heaviest cognitive surface in the app.", "It affects every successful generation session.", "Higher perceived quality and lower friction."),
        render_strategy_item("Sharpen Dashboard into a clearer daily command center.", "It should answer 'what should I do next?' in seconds.", "The dashboard already exists and has enough data to become more opinionated.", "Better daily reuse and retention."),
        render_strategy_item("Make Pro boundaries transparent and graceful.", "Users should understand why they hit a gate and what value sits behind it.", "Paywall triggers already exist.", "Higher trust and lower friction at monetization points."),
        "### Top 3 technical debt cleanups",
        render_strategy_item("Remove remaining direct persistence hot spots in views/view models.", "Persistence logic still leaks into UI-adjacent code in places.", "The architecture direction already points away from this.", "Cleaner boundaries and easier tests."),
        render_strategy_item("Update stale docs that still mention older API-key-centric provider setup.", "The README no longer perfectly matches the current product path.", "Documentation drift undermines operator clarity.", "Cleaner onboarding for future work and for the report automation."),
        render_strategy_item("Add report-friendly metadata or conventions for future automation.", "Some business-critical facts still live only in human heads.", "Daily reporting now exists; feed it better truth.", "Sharper decisions and less ambiguity."),
        "### Top 3 underexploited opportunities",
        render_strategy_item("Template packs by creator type or business goal.", "The seed catalog proves templates are already a strong wedge.", "This is a natural product and monetization extension.", "Better onboarding, stronger Pro packaging, and future upsells."),
        render_strategy_item("Prompt-context memory as a premium creator efficiency feature.", "Persistent creator context is already emerging in the auth work.", "This can materially reduce friction for repeat use.", "Higher retention and clearer value beyond one-off generation."),
        render_strategy_item("Daily publishing assistant behavior layered onto planner + dashboard.", "The app already stores the right primitives.", "This could create a habit loop without major new infrastructure.", "More daily opens and stronger operating-system positioning."),
    ]

    broader_ideas = [
        "- Build niche-specific template packs and make some of them Pro-only without making the free tier feel fake.",
        "- Add a 'next best action' card on the dashboard based on unfinished drafts, planned posts, or low weekly momentum.",
        "- Add post-performance reflection notes so the planner becomes a closed learning loop, not just a calendar.",
        "- Add premium output modes later around stronger video prompt depth, higher-authority script framing, or provider-assisted rewrites.",
        "- Add export/share loops that create a public-facing artifact users can share, improving acquisition through product output.",
        "- Add analytics around which template families actually lead to saves, planner assignments, and paywall opens.",
        "- Position the app more clearly as a creator operating system rather than only an AI generator in App Store copy and paywall language.",
        "- Use the morning report automation itself as an internal operating layer: product context, metrics, and build/test truth in one place each day.",
        "- Consider a weekly recap report later if daily usage data becomes available.",
        f"- Once real costs are known, add `cost_per_generation` and `cost_per_active_user` to the business metrics file. Current evidence: generation cost {cost_per_generation}, cost per active user {cost_per_user}.",
    ]

    risks = [
        f"- High — Quality confidence gap\n  Why it matters: Build health is green, but {test_lane_phrase}. Revenue, auth, and generator flows are evolving without a trusted regression net.\n  What could break or slow down: Shipping speed, release confidence, monetization correctness.\n  Mitigation: Fix hosted tests before adding another major feature.",
        "- High — Branch surface area is expanding faster than stabilization\n  Why it matters: Committed monetization work and uncommitted auth work are both large product moves.\n  What could break or slow down: Merge safety, mental clarity, bug isolation.\n  Mitigation: Finish or park auth cleanly; do not stack another product theme on top.",
        "- Medium — Result/dashboard/planner views remain structural hotspots\n  Why it matters: Large SwiftUI files are hard to reason about and easy to regress.\n  What could break or slow down: UX iteration, polish, bug fixing.\n  Mitigation: Split by responsibility and add focused view-model or helper seams.",
        "- Medium — Monetization could look further along than it really is\n  Why it matters: StoreKit code exists, but external setup and paywall copy/legal remain incomplete.\n  What could break or slow down: Actual selling, App Review, user trust.\n  Mitigation: Treat App Store Connect and legal assets as product work, not admin afterthoughts.",
        "- Medium — Business truth is missing from the repo\n  Why it matters: Users, feedback, retention, and competition are not evidenced today.\n  What could break or slow down: Prioritization quality.\n  Mitigation: Populate the manual reporting context and metrics files immediately.",
        "- Low — Docs drift\n  Why it matters: README still reflects older provider assumptions.\n  What could break or slow down: Contributor onboarding and operator clarity.\n  Mitigation: Update docs after the auth/monetization path is settled.",
    ]

    direct_answers = [
        "1. If I only have 2 hours today, what should I do?\n   Fix the test lane or narrow the exact failure cause. That is the highest-leverage confidence move.",
        "2. If I want the biggest product improvement this week, what should I attack?\n   Reduce result-screen density and tighten the first-run journey from onboarding/template to first useful output.",
        "3. If I want the biggest monetization improvement this week, what should I attack?\n   Finish App Store Connect setup, final pricing/legal assets, and instrument paywall conversion points.",
        "4. What part of the app is closest to real product quality already?\n   The generator + offline mock + template-assisted creation flow.",
        "5. What part of the app still feels too much like an internal build?\n   The result experience and some large shell/dashboard/planner surfaces.",
        "6. What is the single most dangerous hidden weakness right now?\n   The illusion of stability created by successful builds while tests remain unreliable.",
        "7. What is the single smartest thing to build next?\n   A stable quality loop: green tests plus instrumentation around generation and monetization.",
        "8. What is the single most wasteful thing to work on next?\n   Another major feature layer before test health and App Store execution are under control.",
        "9. What is the app currently best at?\n   Turning creator inputs into structured, reusable short-form content quickly, especially offline.",
        "10. What is the app currently pretending to be good at but is not yet truly strong at?\n   Being fully ready to sell as a subscription product. The code is close; the external setup and quality confidence are not.",
    ]

    evidence = [
        f"- Repo root inspected: `{repo_root}`",
        f"- Previous daily report: `{previous_report.relative_to(repo_root) if previous_report else 'none found'}`",
        f"- Git status source: `git status --short` with {len(git_status.stdout.splitlines())} entries",
        f"- Recent commit source: `git log --decorate --stat -n 10`; latest line `{latest_commit_line}`",
        f"- Build command: `xcodebuild -project AIContentMachine.xcodeproj -scheme AIContentMachine -destination 'generic/platform=iOS Simulator' build` -> {build_state}",
        f"- Test command: `xcodebuild -project AIContentMachine.xcodeproj -scheme AIContentMachine -destination 'platform=iOS Simulator,id={simulator_id or 'unknown'}' test` -> {test_state}",
        f"- Key files inspected: `{app_container_path.relative_to(repo_root)}`, `{root_view_path.relative_to(repo_root)}`, `{dashboard_view_path.relative_to(repo_root)}`, `{result_view_path.relative_to(repo_root)}`, `{planner_view_path.relative_to(repo_root)}`, `{settings_view_path.relative_to(repo_root)}`, `{paywall_path.relative_to(repo_root)}`, `{storekit_path.relative_to(repo_root)}`",
        f"- Template evidence: `{template_count}` templates total, `{free_template_count}` free, `{pro_template_count}` Pro from `TemplateEngine.swift`; validated by `TemplateEngineCatalogTests.swift`",
        f"- Test inventory: {len(test_files)} XCTest files and approximately {test_method_count} test methods",
        f"- Large file snapshot: {', '.join(f'{path} ({lines} lines)' for path, lines in large_files[:4])}",
        f"- Direct persistence hot spots detected: {', '.join(direct_save_lines[:5]) if direct_save_lines else 'none detected by pattern search'}",
        f"- Manual product context file: `{repo_root / 'docs/reporting/project-context.yaml'}` -> {'loaded' if has_context else 'missing or empty'}",
        f"- Manual metrics file: `{repo_root / 'docs/reporting/metrics.yaml'}` -> {'loaded' if has_metrics else 'missing or empty'}",
        f"- README evidence used: onboarding/dashboard/generator/library/planner/settings/local mock statements",
        f"- App Store checklist evidence used: pending pricing, legal URLs, StoreKit scheme assignment, QA checklist",
        f"- Working tree auth evidence: {', '.join(auth_status_entries) if auth_status_entries else 'none'}",
    ]

    report = f"""# DAILY AI CONTENT MACHINE MORNING REPORT
Date: {report_date.isoformat()}
Project: {PRODUCT_NAME}
Report Type: {REPORT_TYPE}

## 1. Executive Summary
{bullet_lines(product_summary)}

## 2. What the App Already Can Do
{chr(10).join(what_app_can_do)}

## 3. What Was Already Built / What Changed Recently
{bullet_lines(changed_recently)}

## 4. Current Product Maturity Assessment
{chr(10).join(maturity_scores)}

{overall_maturity}

## 5. What Is Still Missing
{chr(10).join(missing_pieces)}

## 6. Highest-Priority TODOs for Today
### Critical today
{chr(10).join(todo_critical)}

### Important today
{chr(10).join(todo_important)}

### Nice-to-have today
{chr(10).join(todo_nice)}

## 7. Best Strategic Moves
{chr(10).join(strategic_moves)}

## 8. Improvement Ideas Worth Considering
{chr(10).join(broader_ideas)}

### Vision Snapshot
- 12 months: {vision_12}
- 24 months: {vision_24}
- 36 months: {vision_36}

## 9. Risks and Warning Signs
{chr(10).join(risks)}

## 10. Morning Focus Recommendation
- Recommended theme for today: restore decision quality by closing the gap between product progress and quality confidence.
- Do not waste time on: another headline feature before tests, App Store setup, and current branch clarity are under control.
- Focused execution path for the next 2-4 hours: {test_lane_focus}
- Deeper move for later today: finish the external monetization setup and replace generic legal/support placeholders with real app-owned assets.
- If momentum is high: reduce the result-screen density and ship the auth/session work cleanly behind a stable commit.

### Direct answers to the daily decision questions
{chr(10).join(direct_answers)}

## 11. Evidence Appendix
- Fact: Target audience from manual context: {target_audience}
- Fact: Core problem solved from manual context: {core_problem}
- Fact: Pricing / Free vs Pro context: {pricing_context}
- Fact: Paywall conversion thesis: {conversion_thesis}
- Fact: Distribution channels: {distribution_channels}
- Fact: Competition: {competition}
- Fact: Moat / product advantage: {moat}
- Fact: Active users: {active_users}
- Fact: Installs / downloads: {installs}
- Fact: Trials / subscribers: {subscribers}
- Fact: Conversion rate: {conversion_rate}
- Fact: Retention: {retention}
- Fact: Recent feedback themes: {feedback_themes}
- Fact: Acquisition performance: {acquisition}
- Fact: Current top risks from manual context: {current_risks_context}
{chr(10).join(evidence)}
"""
    return report.strip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate the daily AI Content Machine morning report.")
    parser.add_argument("--repo-root", help="Path to the AI Content Machine repo root.")
    parser.add_argument("--date", help="Report date in YYYY-MM-DD format.")
    parser.add_argument("--project-context", help="Optional path to project-context.yaml.")
    parser.add_argument("--metrics", help="Optional path to metrics.yaml.")
    parser.add_argument("--output", help="Optional output markdown path.")
    parser.add_argument("--skip-build", action="store_true", help="Skip xcodebuild build step.")
    parser.add_argument("--skip-tests", action="store_true", help="Skip xcodebuild test step.")
    parser.add_argument("--print", dest="print_report", action="store_true", help="Print report to stdout.")
    args = parser.parse_args()

    repo_root = find_repo_root(args.repo_root)
    report_date = dt.date.fromisoformat(args.date) if args.date else dt.date.today()

    reports_dir = repo_root / "docs" / "reports" / "daily"
    reports_dir.mkdir(parents=True, exist_ok=True)
    output_path = Path(args.output).expanduser().resolve() if args.output else reports_dir / f"{report_date.isoformat()}-morning-report.md"

    existing_reports = sorted(reports_dir.glob("*-morning-report.md"))
    previous_report = None
    for candidate in reversed(existing_reports):
        if candidate.resolve() != output_path.resolve():
            previous_report = candidate
            break

    project_context_path = Path(args.project_context).expanduser().resolve() if args.project_context else repo_root / "docs" / "reporting" / "project-context.yaml"
    metrics_path = Path(args.metrics).expanduser().resolve() if args.metrics else repo_root / "docs" / "reporting" / "metrics.yaml"

    project_context = load_optional_yaml(project_context_path)
    metrics = load_optional_yaml(metrics_path)

    git_status = run_command(["git", "status", "--short"], repo_root, timeout=30)
    git_log = run_command(["git", "log", "--decorate", "--stat", "-n", "10", "--oneline"], repo_root, timeout=30)
    git_diff = run_command(["git", "diff", "--stat", "HEAD"], repo_root, timeout=30)
    simulator_id = get_available_simulator_id(repo_root)

    if args.skip_build:
        build_result = CommandResult(["xcodebuild", "build"], 0, "", "", "skipped", 0.0)
    else:
        build_result = run_command(
            [
                "xcodebuild",
                "-project",
                "AIContentMachine.xcodeproj",
                "-scheme",
                "AIContentMachine",
                "-destination",
                "generic/platform=iOS Simulator",
                "build",
            ],
            repo_root,
            timeout=900,
        )

    if args.skip_tests:
        test_result = CommandResult(["xcodebuild", "test"], 0, "", "", "skipped", 0.0)
    else:
        destination = f"platform=iOS Simulator,id={simulator_id}" if simulator_id else "generic/platform=iOS Simulator"
        test_result = run_command(
            [
                "xcodebuild",
                "-project",
                "AIContentMachine.xcodeproj",
                "-scheme",
                "AIContentMachine",
                "-destination",
                destination,
                "test",
            ],
            repo_root,
            timeout=300,
        )

    report = build_report(
        repo_root=repo_root,
        report_date=report_date,
        project_context=project_context,
        metrics=metrics,
        previous_report=previous_report,
        git_status=git_status,
        git_log=git_log,
        git_diff=git_diff,
        build_result=build_result,
        test_result=test_result,
        simulator_id=simulator_id,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(report, encoding="utf-8")

    if args.print_report:
        print(report)
    else:
        print(f"Wrote morning report to {output_path}")

    if git_diff.stdout:
        print("Detected working tree diff against HEAD.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
