content = """SOURCES=$(shell python3 scripts/read-config.py --sources )
FAMILY=$(shell python3 scripts/read-config.py --family )
DRAWBOT_SCRIPTS=$(shell ls documentation/*.py)
DRAWBOT_OUTPUT=$(shell ls documentation/*.py | sed 's/\\.py/.png/g')

help:
\t@echo "###"
\t@echo "# Build targets for $(FAMILY)"
\t@echo "###"
\t@echo
\t@echo "  make build:  Builds the fonts and places them in the fonts/ directory"
\t@echo "  make test:   Tests the fonts with fontspector"
\t@echo "  make images: Creates PNG specimen images in the documentation/ directory"
\t@echo

build: build.stamp

venv: venv/touchfile

customize: venv
\t. venv/bin/activate; python3 scripts/customize.py

build.stamp: venv sources/config.yaml $(SOURCES)
\trm -rf fonts
\t. venv/bin/activate; gftools builder sources/config.yaml
\ttouch build.stamp

venv/touchfile: requirements.txt
\ttest -d venv || python3 -m venv venv
\t. venv/bin/activate; pip install -Ur requirements.txt
\ttouch venv/touchfile

test: build.stamp
\twhich fontspector || (echo "fontspector not found. Please install it with 'cargo install fontspector'." && exit 1)
\tTOCHECK=$$(find fonts/variable -type f 2>/dev/null); if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f 2>/dev/null); fi ; mkdir -p out/ out/fontspector; fontspector --profile googlefonts -l warn --full-lists --succinct --html out/fontspector/fontspector-report.html --ghmarkdown out/fontspector/fontspector-report.md --badges out/badges $$TOCHECK  || echo '::warning file=sources/config.yaml,title=fontspector failures::The fontspector QA check reported errors in your font. Please check the generated report.'

images: venv $(DRAWBOT_OUTPUT)

%.png: %.py build.stamp
\t. venv/bin/activate; python3 $< --output $@

clean:
\trm -rf venv
\tfind . -name "*.pyc" -delete

update-project-template:
\tnpx update-template https://github.com/googlefonts/googlefonts-project-template/

update: venv
\tvenv/bin/pip install --upgrade pip-tools
\tvenv/bin/pip-compile --upgrade --verbose --resolver=backtracking requirements.in
\tvenv/bin/pip-sync requirements.txt
\tgit commit -m "Update requirements" requirements.txt
\tgit push
"""

with open("Makefile", "w", newline="\n") as f:
    f.write(content)

print("Makefile created successfully with proper tabs!")
