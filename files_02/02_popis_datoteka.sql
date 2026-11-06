-- Lab 2, 2 zadatak

SELECT naziv AS naziv_datoteke
FROM pg_ls_dir('D:/tatjana_labovi/files_02') AS datoteke(naziv)
WHERE lower(naziv) ~ '^customer_.*\.(json|csv|xml)$'
ORDER BY naziv;
