format:
	@swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Android/ \
		./App/ \
		./DataClient/ \
		./iOS/ \
		./LocalizationGenerated/ \
		./Server/ \
		./Shared/ \
		./SharedModels/ \
		./Website/
