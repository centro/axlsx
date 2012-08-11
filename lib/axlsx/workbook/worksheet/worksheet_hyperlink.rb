module Axlsx

  # A worksheet hyperlink object. Note that this is not the same as a drawing hyperlink object.
  class WorksheetHyperlink

    # Creates a new hyperlink object.
    # @note the preferred way to add hyperlinks to your worksheet is the Worksheet#add_hyperlink method
    # @param [Worksheet] worksheet the Worksheet that owns this hyperlink
    # @param [Hash] options options to use when creating this hyperlink
    # @option [String] display Display string, if different from string in string table. This is a property on the hyperlink object, but does not need to appear in the spreadsheet application UI.
    # @option [String] location Location within target. If target is a workbook (or this workbook) this shall refer to a sheet and cell or a defined name. Can also be an HTML anchor if target is HTML file.
    # @option [String] tooltip The tip to display when the user positions the mouse cursor over this hyperlink
    # @option [Symbol] target This is :external by default. If you set it to anything else, the location is interpreted to be the current workbook.
    # @option [String|Cell] ref The location of this hyperlink in the worksheet
    def initialize(worksheet, options={})
      DataTypeValidator.validate "Hyperlink.worksheet", [Worksheet], worksheet
      @worksheet = worksheet
      @target = :external
      options.each do |o|
        self.send("#{o[0]}=", o[1]) if self.respond_to? "#{o[0]}="
      end
      yield self if block_given?
    end

    # String attributes for this object
    STRING_ATTRIBUTES = %w(display location tooltip)

    #Cell location of hyperlink on worksheet.
    # @return [String]
    attr_reader :ref

    # Sets the target for this hyperlink. Anything other than :external instructs the library to treat the location as an in-workbook reference.
    # @param [Symbol] target
    def target=(target)
      @target = target
    end

    # Sets the cell location of this hyperlink in the worksheet
    # @param [String|Cell] The string reference or cell that defines where this hyperlink shows in the worksheet.
    def ref=(cell_reference)
      cell_reference = cell_reference.r if cell_reference.is_a?(Cell)

      Axlsx::validate_string cell_reference
      @ref = cell_reference
    end

    # Dynamically create string attribute accessors
    STRING_ATTRIBUTES.each do |attr|
      class_eval %{
        # The #{attr} attribute reader
        # @return [String]
        attr_reader :#{attr}

        # The #{attr} writer
        # @param [String] value The value to assign to #{attr}
        # @return [String]
        def #{attr}=(value)
          Axlsx::validate_string(value)
          @#{attr}= value
        end
      }
    end

    def relationship
      return unless @target == :external
      Relationship.new HYPERLINK_R, location, :target_mode => :External
    end

    def id
     "rId#{@worksheet.relationships_index_of(self)+1}"
    end

    def to_xml_string(str='')
      h = instance_values.select { |key, value| %w(display ref tooltip).include? key }
      h['r:id'] = id if @target == :external
      h['location'] = location unless @target == :external
      str << '<hyperlink '
      h.map { |key, value| str << key.to_s << '="' << value.to_s << '" ' }
      str << '/>'
    end
  end
end
