# dependencies: grep, sed, make, python3, pandoc

help:
	@echo "to build: make build"
	@echo "to serve: make serve"
	@echo "to clean: make clean"

build:
	@mkdir -p out/
	@echo "---" > out/index.md
	@echo "title: Timo Sarkar" >> out/index.md
	@echo "---" >> out/index.md
	@echo "" >> out/index.md
	@for file in posts/*.md; do \
		if [ -e "$$file" ]; then \
			title=$$(grep '^title:' $$file | sed 's/title: //'); \
			output="out/$$(basename $${file%.md}.html)"; \
			echo "Processing: $$file -> $$output"; \
			echo "[$$title]($$(basename $$output))<br>" >> out/index.md; \
			pandoc "$$file" --metadata post=True --template=template.html -o "$$output"; \
		fi; \
	done
	@pandoc out/index.md --template template.html -o out/index.html

serve:
	@python3 -m http.server --directory out/

clean:
	@rm -rf out/
