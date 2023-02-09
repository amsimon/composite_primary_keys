module ActiveRecord
  module Associations
    class Preloader
      class Association

        def load_records(&block)
          return {} if owner_keys.empty?
          # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
          # Make several smaller queries if necessary or make one query if the adapter supports it
          slices = owner_keys.each_slice(klass.connection.in_clause_length || owner_keys.size)
          @preloaded_records = slices.flat_map do |slice|

            # puts "\nload_records(&block)  slice #{ slice.inspect}\n"

            records_for(slice, &block)
          end
          @preloaded_records.group_by do |record|

            # puts "\nload_records(&block)  convert_key(record[association_key_name]) #{convert_key(record[association_key_name]).inspect}\n"

            possibly_array = record[association_key_name]

            if possibly_array.is_a?(Array)
              convert_key(record[association_key_name].map(&:downcase))
            else
              convert_key(record[association_key_name])
            end

            
            
          end
        end

        # def load_records(&block)
        #   return {} if owner_keys.empty?
        #   # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
        #   # Make several smaller queries if necessary or make one query if the adapter supports it
        #   slices = owner_keys.each_slice(klass.connection.in_clause_length || owner_keys.size)
        #   @preloaded_records = slices.flat_map do |slice|
        #     puts "\nload_records(&block)  slice #{ slice.inspect}\n"
        #     records_for(slice, &block)
        #   end
        #   @preloaded_records.group_by do |record|
        #     puts "\nload_records(&block)  association_key_name #{ association_key_name.inspect}\n"
        #     puts "\nload_records(&block)  record #{ record.inspect}\n"
        #     puts "\nload_records(&block)  record[association_key_name] #{ record[association_key_name].inspect}\n"
            

        #     puts "\nload_records(&block)  convert_key(record[association_key_name]) #{convert_key(record[association_key_name]).inspect}\n"
        #     convert_key(record[association_key_name])

            
            

            
        #   end

        #   puts "\nload_records(&block)  @preloaded_records #{@preloaded_records.inspect}\n"
        # end


        def records_for(ids, &block)
          # CPK
          #scope.where(association_key_name => ids).load(&block)
          # puts "\nrecords_for(ids, &block)  ids #{ ids.inspect}\n"
          if association_key_name.is_a?(Array)
            predicate = cpk_in_predicate(klass.arel_table, association_key_name, ids)
            # puts "\nrecords_for(ids, &block)  predicate #{ predicate.inspect}\n"

            # puts "\nrecords_for(ids, &block)  scope.where(predicate) #{ scope.where(predicate).inspect}\n"

            # puts "\nrecords_for(ids, &block)  scope.where(predicate).load(&block) #{ scope.where(predicate).load(&block).inspect}\n"
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
              # puts "\nowners_by_key  h[key] #{ h[key].inspect}\n"
            end
          end
          # puts "\nowners_by_key  @owners_by_key #{ @owners_by_key.inspect}\n"
          @owners_by_key
        end

        def run(preloader)
          records = load_records do |record|
            # CPK
            #owner = owners_by_key[convert_key(record[association_key_name])]
            # puts "\nrun(preloader) record #{record.inspect}\n"
            key = if association_key_name.is_a?(Array)
                    Array(record[association_key_name]).map do |kkk|
                      k = kkk.to_s.downcase

                      # puts "\nrun(preloader) kkk #{kkk.inspect}\n"
                      convert_key(k)
                    end
                  else
                    convert_key(record[association_key_name].to_s.downcase)
                  end
            
            owner = owners_by_key[key]
            # puts "\nrun(preloader) owner #{owner.inspect}\n"
            association = owner.association(reflection.name)
            # puts "\nrun(preloader) association #{association.inspect}\n"
            association.set_inverse_instance(record)
          end

          # puts "\nrun(preloader) records #{records.inspect}\n"

          owners.each do |owner|

            # puts "\nrun(preloader) owner #{owner.inspect}\n"
            # puts "\nrun(preloader) owner_key_name) #{owner_key_name.inspect}\n"
            # puts "\nrun(preloader) owner[owner_key_name]) #{owner[owner_key_name].inspect}\n"
            # puts "\nrun(preloader) records[convert_key(owner[owner_key_name])] #{records[convert_key(owner[owner_key_name])].inspect}\n"
 
            possibly_array = owner[owner_key_name]

            if possibly_array.is_a?(Array)
              ok = owner[owner_key_name].map(&:downcase)
            else
              ok = possibly_array
            end

            associate_records_to_owner(owner, records[convert_key(ok)] || [])
          end
        end
      end
    end
  end
end