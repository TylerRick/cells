module Cell
  class TemplateFinder

    attr_accessor :view_paths

    def initialize(cell, state, action_view)
      @cell = cell
      @state = state
      @action_view = action_view
      @view_paths = []
    end

    # Return two values: path_without_extension and extension
    def path_and_extension(path)

      state_view = @cell.view_for_state(@state)

      if state_view
        extension = File.extname(state_view)[1..-1]
        path_without_extension = File.join(File.dirname(state_view), File.basename(state_view, '.' + extension))
      else
        ext = @action_view.template_format
        path_without_extension, extension = resolve_cells_path_and_extension(@cell, @state, ext)
      end

      # This code also exists in Rails:
      # Try again if we couldn't find a js template and try with html instead.
      # This is useful when the user is calling insert_html like this:
      #   insert_html(:element_id, render_cell(:something))
      # In that case, we'd want to return some html instead.
      if @action_view.template_format == :js and path_without_extension.blank? and extension.blank?
        path_without_extension, extension = resolve_cells_path_and_extension(@cell, @state, :html)
      end
      @view_paths << path_without_extension+'.'+extension
      [path_without_extension, extension]
    end

    # Render the template, using 'cells' dir instead of 'views'.
    # First check for this template in the application. If it exists, the user has
    # overridden anything from the plugin, so use it (unless we're testing plugins).
    def resolve_cells_path_and_extension(cell, state, type_ext)
      resolve_cell = cell.class
      
      while resolve_cell != Cell::Base
        possible_cell_paths.each do |path|
          template_handler_extensions.each do |ext|
            if File.exists?(path_for_cell_template_with_type_extension(path, resolve_cell.cell_name, state, type_ext) +'.'+ext)
              return [path_for_cell_template_with_type_extension(path, resolve_cell.cell_name, state, type_ext), ext]
            end
          end
        end
        resolve_cell = resolve_cell.superclass
      end
      return ["", ""]
    end

    # To see if the template can be found, make list of possible cells paths, according to:
    # If Engines loaded: then append paths in order so that more recently started plugins 
    # will take priority and RAILS_ROOT/app/cells with highest prio.
    # Engines not-loaded: then only RAILS_ROOT/app/cells
    def possible_cell_paths
      if Object.const_defined?(:Engines)
        Rails.plugins.by_precedence.map {|plugin| plugin.directory + '/app/cells'}.unshift(RAILS_ROOT + '/app/cells')
      else
        RAILS_ROOT + '/app/cells'
      end
    end
    
    def pick_template(template_path, extension)
      if template_path.blank? || extension.blank?
        nil
      else
        "#{template_path}.#{extension}"
      end
    end

    def pick_template_extension(path)
      nil
    end

    def template_handler_extensions
      ActionView::Template.template_handler_extensions
    end

    def path_for_cell_template_with_type_extension(cells_path, cell_name, state, type_ext)
      "#{cells_path}/#{cell_name}/#{state}.#{type_ext}"
    end

    def find_base_path_for(template_file_name)
      @view_paths.find { |path| [path] == template_file_name }
    end

  end
end