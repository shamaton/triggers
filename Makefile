OSOBA_PATH := osoba
OSOBA_BRANCH := main
TH_PATH := th
TH_BRANCH := main

pull:
	git pull --recurse-submodules && git submodule update --init --recursive

update-osoba:
	git submodule update --init $(OSOBA_PATH)
	git -C $(OSOBA_PATH) fetch origin $(OSOBA_BRANCH)
	git -C $(OSOBA_PATH) checkout $(OSOBA_BRANCH)
	git -C $(OSOBA_PATH) pull --ff-only origin $(OSOBA_BRANCH)

update-threads:
	git submodule update --init $(TH_PATH)
	git -C $(TH_PATH) fetch origin $(TH_BRANCH)
	git -C $(TH_PATH) checkout $(TH_BRANCH)
	git -C $(TH_PATH) pull --ff-only origin $(TH_BRANCH)

.PHONY: pull update-osoba update-threads
