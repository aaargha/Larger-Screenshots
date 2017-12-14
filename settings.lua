data:extend({
   {
      type = "int-setting",
      name = "LargerScreenshots_max_res",
      setting_type = "runtime-per-user",
      default_value = 8192,
	  minimum_value = 100,
	  maximum_value = 16384,
      per_user = true,
   },
   {
      type = "int-setting",
      name = "LargerScreenshots_max_res_aa",
      setting_type = "runtime-per-user",
      default_value = 4096,
	  minimum_value = 100,
	  maximum_value = 8192,
      per_user = true,
   }
})