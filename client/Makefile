integration-test:
	flutter test integration_test/app_test.dart \
		--reporter=expanded \
		--file-reporter=json:tools/test-reporter/tests.json

report:
	dart run tools/test-reporter/reporter.dart tools/test-reporter/tests.json

report-html:
	dart run tools/test-reporter/reporter.dart tools/test-reporter/tests.json --html tools/test-reporter/report.html

report-json:
	dart run tools/test-reporter/reporter.dart tools/test-reporter/tests.json --json tools/test-reporter/report.json