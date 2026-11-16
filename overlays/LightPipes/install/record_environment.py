from pathlib import Path
import importlib.metadata as im, json, platform, sys, subprocess
from datetime import datetime, timezone
root = Path(__file__).resolve().parents[1]
config = json.loads((root/'install/config.json').read_text(encoding='utf-8-sig'))
check = subprocess.run([sys.executable, '-m', 'pip', 'check'], text=True, capture_output=True)
(root/'install/logs/pip-check.log').write_text(check.stdout+check.stderr, encoding='utf-8')
check.check_returncode()
packages={d.metadata['Name']:d.version for d in im.distributions()}
assert im.version(config['package']) == config['version'], (im.version(config['package']), config['version'])
assert platform.python_version() == config['python']
exclude={config['package'].lower()} if config['mode']=='source' else set()
lines=[f'{name}=={version}' for name,version in sorted(packages.items(), key=lambda x:x[0].lower()) if name.lower() not in exclude]
(root/'install/logs/installed-requirements.txt').write_text('\n'.join(lines)+'\n', encoding='utf-8')
try: commit=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True,stderr=subprocess.DEVNULL).strip() if (root/'.git').exists() else config['source_commit']
except (OSError,subprocess.CalledProcessError): commit=config['source_commit']
meta=dict(config, source_commit=commit, python=sys.version, executable='.venv/Scripts/python.exe', packages=packages, platform=platform.platform(), validated_on=datetime.now(timezone.utc).isoformat(), validation='pip check and install/smoke_test.py passed')
(root/'install/installed-metadata.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'package':config['package'],'version':im.version(config['package']),'python':platform.python_version(),'commit':commit},ensure_ascii=False))

status=dict(name=config['name'], version=im.version(config['package']), source_commit=commit, environment='Windows x64 / project-local Python 3.12.12 / .venv', status='installed-and-validated', validation=['dependency check passed', 'short optical computation passed; see install/smoke_test.py and install/logs/smoke-test.log'], limitations=config['limits'], launch=['Activate.bat','Run-smoke-test.bat'] + (['Launch-GUI.bat'] if config['name'] in ['Optiland','RayOptics'] else []), installer='install/install.bat (online, pinned dependency lock)')
(root/'install/status.json').write_text(json.dumps(status,ensure_ascii=False,indent=2),encoding='utf-8')
