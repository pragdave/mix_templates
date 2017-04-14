defmodule TemplatesTest do
  use ExUnit.Case
  alias MixTemplates,       as: MT
  alias MixTemplates.Cache
  
  def load_templates(list) when is_list(list) do
    Enum.each(list, &load_templates/1)
  end
  
  def load_templates(src) do
    Path.join([__DIR__, "../test_templates", src])
    |> Cache.install_from_local_tree
  end
  
  describe "templates" do
  
    setup do
      load_templates(["one", "two"])
      :ok
    end
    
    test "are added to the cache" do
      template1 = MT.find(:one)
      assert template1.name == :one
      template2 = MT.find(:two)
      assert template2.name == :two      
    end
  
    test "know their source directory" do
      template = MT.find(:one)
      dir = template.source_dir
      assert String.starts_with?(dir, Mix.Utils.mix_home)
      assert String.ends_with?(dir, "/template/$PROJECT_NAME$")
    end
  end
  
  describe "check for existing target" do
    import MixTemplates
  
    @target                Path.join(__DIR__, "_target")
    @existing_project      "project"
    @existing_project_path Path.join(@target, @existing_project)
    @existing_file         "some_file"
    @existing_file_path    Path.join(@target,  @existing_file)
    @nonfile_target        Path.join(__DIR__, "_npt")
    @new_project           "new_project"
    @new_project_path      Path.join(@target, @new_project)
    
    setup do
      File.mkdir!(@target)
      File.mkdir(@existing_project_path)
      File.write!(@nonfile_target, "hello")
      File.write!(@existing_file_path,  "world")
      on_exit fn ->
        File.rm!(@nonfile_target)
        File.rm!(@existing_file_path)
        File.rmdir!(@existing_project_path)
        File.rmdir!(@target)
      end
    end
  
    test "fails if target dir doesn't exist" do
      assert { :error, msg } = check_existence_of("nonexistent", "name")
      assert String.contains?(msg, "does not exist")
    end
  
    test "fails if target exists but isn't a directory" do
      assert { :error, msg } = check_existence_of(@nonfile_target, "name")
      assert msg == "'#{@nonfile_target}' is not a directory"
    end
  
    test "fails if project exists but is not a directory" do
      assert { :error, msg } = check_existence_of(@target, @existing_file)
      assert msg == "'#{@existing_file_path}' exists but is not a directory"
    end
  
    test "flags an existing project" do
      assert { :maybe_update, @existing_project_path } = check_existence_of(@target, @existing_project)
    end
  
    test "flags a new project" do
      assert { :need_to_create, @new_project_path } = check_existence_of(@target, @new_project)
    end
  end
  
  test "merging projects not supported" do
    dummy_assigns = %{ assigns: %{}}
    assert { :error, msg } = MT.create_or_merge({:maybe_update, "a"}, "b", dummy_assigns)
    assert msg == "Updating an existing project is not yet supported"
  end
  
  
  test "can copy a file and expand the content" do
    assigns = %{ one: "number 1", two: "deux" }
    source  = "_in"
    dest    = "_out"
    File.write!(source, "first: <%= @one %>\nsecond: <%= @two %>")
    MT.copy_and_expand(source, dest, assigns: assigns)
    result = File.read!(dest)
    File.rm_rf!(source)
    File.rm_rf!(dest)
    assert result == "first: number 1\nsecond: deux"
  end
  
  test "renames a target file if its name is $PROJECT_NAME$" do
    assigns = %{ one: "number 1", two: "deux", project_name: "fred" }
    source  = Path.join([__DIR__, "data/tree1/$PROJECT_NAME$"])
    dest    = "_out"
    MT.copy_dir(source, dest, assigns: assigns)
    assert File.exists?("_out/lib/fred.ex")
    assert File.exists?("_out/test/fred_test.exs")
    
    File.rm_rf!(dest)
   end
end
