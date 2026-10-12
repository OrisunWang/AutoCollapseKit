#!/usr/bin/env python3
"""Generate isolated integration hosts, avoiding dependency leakage between combinations."""
from pathlib import Path
import argparse
import subprocess


def generate(root: Path, combination: str, linkage: str, snapkit_version: str | None) -> Path:
    """Generate sources/configuration only; CocoaPods installation is a separate step."""
    suffix = f'-snapkit{snapkit_version}' if snapkit_version else ''
    fixture = root / '.build' / 'fixtures' / f'{combination}-{linkage}{suffix}'
    fixture.mkdir(parents=True, exist_ok=True)
    snap = combination in ('snapkit', 'both')
    masonry = combination in ('masonry', 'both')
    flags = (['ACK_HAS_SNAPKIT'] if snap else []) + (['ACK_HAS_MASONRY'] if masonry else [])
    test_sources = [root / 'Tests' / 'ACKCoreTests.m']
    if snap:
        test_sources.append(root / 'Tests' / 'ACKSnapKitTests.swift')
    if masonry:
        test_sources.append(root / 'Tests' / 'ACKMasonryTests.m')
    if snap and masonry:
        test_sources += [root / 'Tests' / 'ACKMixedTests.swift', root / 'Example/Sources/ACKMasonryExample.m']
        (fixture / 'Tests-Bridging.h').write_text(f'#import "{root}/Example/Sources/ACKMasonryExample.h"\n')
    extra_settings = ''
    if snap and masonry:
        extra_settings = '        SWIFT_OBJC_BRIDGING_HEADER: Tests-Bridging.h\n'
    sources_yaml = '\n'.join(f'      - path: "{source}"' for source in test_sources)
    (fixture / 'project.yml').write_text(f'''# Generated validation host, not a production App configuration.
name: ACKValidation
options:
  settingPresets: project
  deploymentTarget:
    iOS: "13.0"
settings:
  base:
    SDKROOT: iphoneos
    LD_RUNPATH_SEARCH_PATHS: "$(inherited) @executable_path/Frameworks @loader_path/Frameworks"
    GENERATE_INFOPLIST_FILE: YES
    SWIFT_VERSION: "5.0"
    TARGETED_DEVICE_FAMILY: "1,2"
targets:
  ACKValidation:
    type: application
    platform: iOS
    sources:
      - path: "{root}/Tests/ACKValidationHost.m"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.AutoCollapseKitValidation.{combination}.{linkage}
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
  ACKTests:
    type: bundle.unit-test
    platform: iOS
    sources:
{sources_yaml}
    dependencies:
      - target: ACKValidation
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.AutoCollapseKitTests.{combination}.{linkage}
        GCC_PREPROCESSOR_DEFINITIONS: "$(inherited) {' '.join(flag + '=1' for flag in flags)}"
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) {' '.join(flags)}"
{extra_settings}schemes:
  ACKValidation:
    build:
      targets:
        ACKValidation: all
        ACKTests: [test]
    test:
      targets: [ACKTests]
''')
    selected = {'core': ['Core'], 'snapkit': ['SnapKit'], 'masonry': ['Masonry'], 'both': ['SnapKit', 'Masonry']}[combination]
    pods = '\n'.join(f"  pod 'AutoCollapseKit/{adapter}', :path => '{root}'" for adapter in selected)
    if snap and snapkit_version:
        pods += f"\n  pod 'SnapKit', '{snapkit_version}'"
    framework_line = "use_frameworks! :linkage => :static\n" if linkage == 'framework' else ''
    (fixture / 'Podfile').write_text(f'''platform :ios, '13.0'
{framework_line}use_modular_headers!
project 'ACKValidation.xcodeproj'
target 'ACKValidation' do
{pods}
  target 'ACKTests' do
    inherit! :complete
  end
end
''')
    subprocess.run(['xcodegen', 'generate'], cwd=fixture, check=True)
    return fixture


def main() -> None:
    """Expose one fixture or the full eight-case matrix to local developers and CI."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--combination', choices=['core', 'snapkit', 'masonry', 'both', 'all'], default='all')
    parser.add_argument('--linkage', choices=['library', 'framework', 'all'], default='all')
    parser.add_argument('--snapkit-version', help='Optional minimum-version compatibility pin (5.6.0).')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    combinations = ['core', 'snapkit', 'masonry', 'both'] if args.combination == 'all' else [args.combination]
    linkages = ['library', 'framework'] if args.linkage == 'all' else [args.linkage]
    for combination in combinations:
        for linkage in linkages:
            print(generate(root, combination, linkage, args.snapkit_version))


if __name__ == '__main__':
    main()
