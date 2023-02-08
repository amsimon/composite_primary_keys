module ActiveRecord
  module Associations
    class Preloader
      class Association
        def records_for(ids, &block)
          # CPK
          #scope.where(association_key_name => ids).load(&block)

          if association_key_name.is_a?(Array)
            predicate = cpk_in_predicate(klass.arel_table, association_key_name, ids)
            scope.where(predicate).load(&block)
          else
            scope.where(association_key_name => ids).load(&block)
          end
        end

        def owners_by_key
          unless defined?(@owners_by_key)
            @owners_by_key = owners.each_with_object({}) do |owner, h|
              # CPK
              #key = convert_key(owner[owner_key_name])
              key = if owner_key_name.is_a?(Array)
                      Array(owner_key_name).map do |key_name|
                        convert_key(owner[key_name].to_s.downcase)
                      end
                    else
                      convert_key(owner[owner_key_name].to_s.downcase)
                    end

              h[key] = owner if key
              puts "owners_by_key  h[key] #{ h[key].inspect}"
            end
          end
          puts "owners_by_key  @owners_by_key #{ @owners_by_key.inspect}"
          @owners_by_key
        end

        def run(preloader)
          records = load_records do |record|
            # CPK
            #owner = owners_by_key[convert_key(record[association_key_name])]

            key = if association_key_name.is_a?(Array)
                    Array(record[association_key_name]).map do |kkk|
                      k = kkk.to_s.downcase
                      convert_key(k)
                    end
                  else
                    convert_key(record[association_key_name].to_s.downcase)
                  end

            owner = owners_by_key[key]
            puts "run(preloader) owner #{owner.inspect}"
            association = owner.association(reflection.name)
            puts "run(preloader) association #{association.inspect}"
            association.set_inverse_instance(record)
          end

          owners.each do |owner|
            associate_records_to_owner(owner, records[convert_key(owner[owner_key_name])] || [])
          end
        end
      end
    end
  end
end