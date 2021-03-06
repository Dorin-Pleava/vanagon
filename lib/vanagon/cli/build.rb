require 'docopt'

class Vanagon
  class CLI
    class Build < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        build [options] <project-name> <platforms> [<targets>]

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [base, local, docker, pooler] [default: pooler]
          -o, --only-build COMPONENT,COMPONENT,...
                                           Only build listed COMPONENTs
          -p, --preserve [RULE]            Rule for VM preservation: never, on-failure, always
                                             [Default: always]
          -r, --remote-workdir DIRECTORY   Working directory on the remote host
          -s, --skipcheck                  Skip the "check" stage when building components
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        puts e.message
        exit 1
      end

      def run(options) # rubocop:disable Metrics/AbcSize
        project = options[:project_name]
        platform_list = options[:platforms].split(',')
        target_list = []
        unless options[:targets].nil? || options[:targets].empty?
          target_list = options[:targets].split(',')
        end

        platform_list.zip(target_list).each do |pair|
          platform, target = pair
          artifact = Vanagon::Driver.new(platform, project, options.merge({ 'target' => target }))
          artifact.run
        end
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--remote-workdir' => :"remote-workdir",
          '--configdir' => :configdir,
          '--engine' => :engine,
          '--skipcheck' => :skipcheck,
          '--preserve' => :preserve,
          '--only-build' => :only_build,
          '<project-name>' => :project_name,
          '<platforms>' => :platforms,
          '<targets>' => :targets
        }
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end

      def options_validate(options)
        # Handle --preserve option checking
        valid_preserves = %w[always never on-failure]
        unless valid_preserves.include? options[:preserve]
          raise InvalidArgument, "--preserve option can only be one of: " +
                                 valid_preserves.join(', ')
        end
        options[:preserve] = options[:preserve].to_sym
        return options
      end
    end
  end
end
