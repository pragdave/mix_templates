defmodule MixTemplates.Specs do
  alias MixTemplates.Cache

  @doc """
  Extra the specs (command line options that this template uses) from a
  a template and all its parents.
  """
  def accumulate_specs(template, base_option_specs) do
    if parent_name = template.based_on() do
      parent_module = Cache.find_template(parent_name)
      template.options() ++ accumulate_specs(parent_module, base_option_specs)
    else
      template.options() ++ base_option_specs
    end
  end
end
