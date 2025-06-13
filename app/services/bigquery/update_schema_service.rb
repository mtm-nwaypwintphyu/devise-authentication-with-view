module Bigquery
  class UpdateSchemaService

    def initialize(bigquery:, dataset_id:, table_id:, existing_fields:, schema_fields:)
      @bigquery = bigquery
      @dataset_id = dataset_id
      @table_id = table_id
      @existing_fields = existing_fields
      @schema_fields = schema_fields
    end
    
    def call
      compare_result = compare_schemas(@existing_fields, @schema_fields)
      added_fields    = compare_result[:added]
      removed_fields  = compare_result[:removed]
      renamed_fields  = compare_result[:renamed]
      retyped_fields  = compare_result[:retyped]
      if only_added?(added_fields, removed_fields, renamed_fields, retyped_fields)
        apply_additions(added_fields)
        return { success: true, message: "New fields added to schema successfully." }
      elsif 
      modify_schema?(added_fields,removed_fields,renamed_fields,retyped_fields)
        apply_modification(added_fields,removed_fields,renamed_fields,retyped_fields)
        return { success: true, message: "Create new table with modified fields successfully." }
      end

      { success: false, error: "Schema changes include non-additive changes. Manual review required." }
    end

    private

    def compare_schemas(existing_schema, incoming_schema)
      existing_map = existing_schema.to_h { |f| [f[:name].downcase, f] }
      incoming_map = incoming_schema.to_h { |f| [f[:name].downcase, f] }

      added   = incoming_map.keys - existing_map.keys
      removed = existing_map.keys - incoming_map.keys

      retyped = (existing_map.keys & incoming_map.keys).each_with_object([]) do |name, changes|
        if existing_map[name][:type].downcase != incoming_map[name][:type].downcase
          changes << { name: name, from: existing_map[name][:type], to: incoming_map[name][:type] }
        end
      end

      renamed = []
      removed.each do |old_name|
        old_type = existing_map[old_name][:type].downcase
        guess = added.find { |new_name| incoming_map[new_name][:type].downcase == old_type }
        if guess
          renamed << { from: old_name, to: guess }
          added.delete(guess)
        end
      end

      {
        added: added.map { |name| incoming_map[name] },
        removed: removed.map { |name| existing_map[name] },
        retyped: retyped,
        renamed: renamed
      }
    end

    def only_added?(added, removed, renamed, retyped)
      added.any? && removed.empty? && renamed.empty? && retyped.empty?
    end

    def modify_schema?(added, removed, renamed, retyped)
      !added.any? || !removed.empty? || !renamed.empty? || !retyped.empty?
    end

    def apply_additions(fields)
      fields.each do |field|
        column_name = "`#{field[:name]}`"
        column_type = field[:type].upcase

        sql = <<~SQL
          ALTER TABLE `#{@bigquery.project}`.`#{@dataset_id}`.`#{@table_id}`
          ADD COLUMN IF NOT EXISTS #{column_name} #{column_type} 
        SQL

        @bigquery.query(sql)
      end
    end

    def apply_modification(added,removed,renamed,retyped)
      project = @bigquery.project
      dataset = @dataset_id
      old_table = @table_id
      new_table = "#{old_table}_updated_#{Time.now.to_i}"

      unchanged_fields = @existing_fields.reject do |field|
        removed.any? { |r| r[:name] == field[:name] } ||
        retyped.any? { |rt| rt[:name] == field[:name] } ||
        renamed.any? { |rn| rn[:from] == field[:name] }
      end

      retyped_fields = retyped.map { |f| { name: f[:name], type: f[:to] } }

      renamed_fields = renamed.map do |f|
        original_type = @existing_fields.find { |ef| ef[:name] == f[:from] }[:type]
        { name: f[:to], type: original_type }
      end

      new_schema = unchanged_fields + retyped_fields + renamed_fields + added

      columns_sql = new_schema.map { |f| "`#{f[:name]}` #{f[:type].upcase}"}.join(",\n ")

      # create new table with old,new,modify schema
      create_sql = <<~SQL
        CREATE TABLE `#{project}.#{dataset}.#{new_table}` (
          #{columns_sql}
        )
      SQL

      @bigquery.query (create_sql)
 
    end
  end
end