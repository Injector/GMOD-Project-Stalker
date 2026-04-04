CStalkerConfig = {}

CStalkerConfig.RanksProgress =
{
	0,
	300,
	600,
	900
}

CStalkerConfig.AttitudeProgress =
{
	{ minimum = -1001 }, -- awful
	{ minimum = -1000, maximum = -141 }, -- very bad
	{ minimum = -150, maximum = -51 }, -- bad
	{ minimum = -50, maximum = 49 }, -- neutral
	{ minimum = 50, maximum = 149 }, -- good
	{ minimum = 150, maximum = 999 }, -- very good
	{ minimum = 1000 } -- nice
}