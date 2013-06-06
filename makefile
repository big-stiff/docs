# Makefile for MongoDB Sphinx documentation
MAKEFLAGS += -j -r --no-print-directory
include bin/makefile.bootstrap
include bin/makefile.dynamic

############# Meta targets that control the build and publication process. #############
publish:$(sphinx-content) $(static-content)
	@echo [build]: $(manual-branch) branch is succeessfully deployed to '$(public-output)'.

############# Targets that define the production build process #############
# Generating files with build specific info.
conf.py:meta.yaml pdfs.yaml
setup:source/includes/hash.rst composite-pages.yaml meta.yaml
	@mkdir -p $(public-branch-output) $(public-output)
	@echo [build]: created $(public-branch-output) and $(public-output)
meta.yaml:
	@bin/docs_meta.py yaml $@
	@echo [meta]: regenerated $@
composite-pages.yaml:bin/composite-pages.yaml
	@cp $< $@
	@echo [meta]: coppied compsite pages $@ file
pdfs.yaml:bin/makecloth/data/pdfs.yaml
	@cp $< $@
	@echo [meta]: coppied pdf pages $@ file
source/includes/hash.rst:
	@$(PYTHONBIN) bin/rstcloth/hash.py $@
	@echo [build]: \(re\)generated $@.
$(public-branch-output)/release.txt:$(public-branch-output)
	@echo $(last-commit) >|$@
	@echo [build]: generated '$@' with current release hash.

# migrating and processing dirhtml and singlehtml content.
$(public-output)/ $(output):
	@mkdir -p $@
	@echo [build]: created $@
$(public-output)/.htaccess:bin/htaccess.yaml bin/htaccess.py $(public-output)/
	@$(PYTHONBIN) bin/htaccess.py $@
$(public-branch-output):$(branch-output)/dirhtml
	@mkdir -p $@
	@rsync -a $</ $@/
	@rm -rf $(public-branch-output)/meta/reference $(public-branch-output)/meta/use-cases
	@touch $@
	@echo [build]: migrated '$</*' to '$@'
$(public-branch-output)/single:$(branch-output)/singlehtml
	@mkdir -p $@
	@rsync -a $</ $@/
	@rm -f $@/contents.html
	@touch $@
	@echo [build]: migrated '$</*' to '$@'
$(public-branch-output)/single/index.html:$(branch-output)/singlehtml/contents.html
	@cp $< $@
	@sed $(SED_ARGS_FILE) -e 's/href="contents.html/href="index.html/g' \
			      -e 's/name="robots" content="index"/name="robots" content="noindex"/g' \
			      -e 's/(href=")genindex.html"/\1..\/genindex\/"/g' $@
	@echo [single]: generating and processing '$@' page
$(branch-output)/sitemap.xml.gz:$(public-branch-output) $(public-branch-output)/release.txt $(public-output)/manual error-pages links 
	@echo -e "----------\n[sitemap]: build started\: `date`" >> $(branch-output)/sitemap-build.log
	@$(PYTHONBIN) bin/sitemap_gen.py --testing --config=conf-sitemap.xml 2>&1 >> $(branch-output)/sitemap-build.log
	@echo [sitemap]: sitemap build complete at `date`.
	@echo "[sitemap]: build finished: `date`" >> $(branch-output)/sitemap-build.log

############# General purpose targets. Not used (directly) in the production build #############
tags:
	@etags -I --language=none --regex=@bin/etags.regexp `find source -name "*.txt" | grep -v "\.#"`
	@echo "[dev]: etags generation complete."
