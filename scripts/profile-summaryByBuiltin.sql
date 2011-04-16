SELECT 
	ruleName
	, rule
	, kind
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
FROM data
WHERE 
	runName NOT LIKE 'tmpSemanticCalibration'
	AND (kind LIKE 'macro' OR kind LIKE 'builtin' OR kind LIKE 'cooling' OR kind LIKE 'heating')
GROUP BY 
	rule
ORDER BY
	matches DESC