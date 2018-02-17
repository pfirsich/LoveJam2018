entityTypes["sprite"] = {
	label = "Sprite",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "sprite",
			componentType = "Sprite",
			imagePath = "../images/cosine.png"
		},
		{
			id = "parallaxX",
			componentType = "MetadataNumber",
			value = 1.0,
			label = "Parallax X",
			__category = "Smash",
		},
		{
			id = "parallaxY",
			componentType = "MetadataNumber",
			value = 1.0,
			label = "Parallax Y",
			__category = "Smash",
		},
		{
			id = "frontLayer",
			componentType = "MetadataBoolean",
			value = true,
			label = "In front of player layer",
			__category = "Smash",
		},
	}
}

entityTypes["polygon"] = {
	label = "Polygon",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "polygon",
			componentType = "SimplePolygon",
			color = {0, 0, 0, 255},
		},
		{
			id = "solid",
			componentType = "MetadataBoolean",
			value = true,
			label = "Solid",
			__category = "Ninjagame",
		},
		{
			id = "kunaiSolid",
			componentType = "MetadataBoolean",
			value = true,
			label = "Solid for Kunai",
			__category = "Ninjagame",
		},
		{
			id = "transparent",
			componentType = "MetadataBoolean",
			value = false,
			label = "Transparent",
			__category = "Ninjagame",
		},
		{
			id = "destructible",
			componentType = "MetadataBoolean",
			value = false,
			label = "Destructible",
			__category = "Ninjagame",
		},
		{
			id = "openable",
			componentType = "MetadataBoolean",
			value = false,
			label = "Openable",
			__category = "Ninjagame",
		},
	}
}

entityTypes["spawnzone"] = {
	label = "Spawnzone",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "polygon",
			componentType = "SimplePolygon",
			color = {0, 255, 0, 100},
		},
		{
			id = "team",
			componentType = "MetadataBoolean",
			value = true,
			label = "Defender?",
			__category = "Ninjagame",
		},
	}
}

entityTypes["levelbounds"] = {
	label = "Level bounds",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "polygon",
			componentType = "SimplePolygon",
			color = {40, 60, 130, 255},
		},
	}
}

entityTypes["objective_steal"] = {
	label = "Steal Objective",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "sprite",
			componentType = "Sprite",
			imagePath = "../images/steal_objective.png"
		},
	}
}
