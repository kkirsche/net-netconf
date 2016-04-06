## -----------------------------------------------------------------------
## This file contains the Junos specific RPC methods that are generated
## specifically and different as generated by the Netconf::RPC::Builder
## module.  These are specifically the following:
##
##   get_configuration      - alternative NETCONF: 'get-config'
##   load_configuration     - alternative NETCONF: 'edit-config'
##   lock_configuration     - alternative NETCONF: 'lock'
##   commit_configuration   - alternative NETCONF: 'commit'
##
## note: unlock_configuration is not included in this file since
##       the Netconf::RPC::Builder works "as-is" in this case
## -----------------------------------------------------------------------

module Netconf
  module RPC
    module Junos

      def lock_configuration
        lock('candidate')
      end

      def check_configuration
        validate('candidate')
      end

      def commit_configuration(params = nil, attrs = nil)
        rpc = Netconf::RPC::Builder.commit_configuration(params, attrs)
        Netconf::RPC.set_exception(rpc, Netconf::CommitError)
        @trans.rpc_exec(rpc)
      end

      def nokogiri_case(arg)
        filter = case arg
                 when Nokogiri::XML::Builder  then arg.doc.root
                 when Nokogiri::XML::Document then arg.root
                 else arg
                 end
      end

      def get_configuration(*args)
        filter = nil

        while arg = args.shift
          case arg.class.to_s
          when /^Nokogiri/
            nokogiri_case(arg)
          when 'Hash' then attrs = arg
          end
        end

        rpc = Nokogiri::XML('<rpc><get-configuration/></rpc>').root
        Netconf::RPC.add_attributes(rpc.first_element_child, attrs) if attrs

        if block_given?
          Nokogiri::XML::Builder.with(rpc.at('get-configuration')) do |xml|
            xml.configuration do
              yield(xml)
            end
          end
        elsif filter
          # filter must have toplevel = <configuration>
          # *MUST* use the .dup so we don't disrupt the original filter
          rpc.first_element_child << filter.dup
        end

        @trans.rpc_exec(rpc)
      end

      def load_configuration(*args)
        config = nil

        # default format is XML
        attrs = { format: 'xml' }

        while arg = args.shift
          case arg.class.to_s
          when /^Nokogiri/
            nokogiri_case(arg)
          when 'Hash' then attrs.merge! arg
          when 'Array' then config = arg.join("\n")
          when 'String' then config = arg
          end
        end

        case attrs[:format]
        when 'set'
          toplevel = 'configuration-set'
          attrs[:format] = 'text'
          attrs[:action] = 'set'
        when 'text'
          toplevel = 'configuration-text'
        when 'xml'
          toplevel = 'configuration'
        end

        rpc = Nokogiri::XML('<rpc><load-configuration/></rpc>').root
        ld_cfg = rpc.first_element_child
        Netconf::RPC.add_attributes(ld_cfg, attrs) if attrs

        if block_given?
          if attrs[:format] == 'xml'
            Nokogiri::XML::Builder.with(ld_cfg) do |xml|
              xml.send(toplevel) do
                yield(xml)
              end
            end
          else
            config = yield  # returns String | Array(of stringable)
            config = config.join("\n") if config.class == Array
          end
        end

        if config
          if attrs[:format] == 'xml'
            # config assumes toplevel = <configuration> given
            ld_cfg << config.dup # duplicate the config so as to not distrupt it
          else
            # config is stringy, so just add it as the text node
            c_node = Nokogiri::XML::Node.new(toplevel, rpc)
            c_node.content = config
            ld_cfg << c_node
          end
        end

        # set a specific exception class on this RPC so it can be
        # properlly handled by the calling enviornment

        Netconf::RPC.set_exception(rpc, Netconf::EditError)
        @trans.rpc_exec(rpc)
      end # load_configuration

      def command(cmd_str, attrs = nil)
        rpc = Nokogiri::XML("<rpc><command>#{cmd_str}</command></rpc>").root
        Netconf::RPC.add_attributes(rpc.at('command'), attrs) if attrs
        @trans.rpc_exec(rpc)
      end

      ## contributed by 'dgjnpr'
      def request_pfe_execute(params = nil)
        raise ArgumentError, 'Manditorary argument :target missing' unless params[:target]
        raise ArgumentError, 'Manditorary argument :command missing' unless params[:command]

        rpc_nx = Nokogiri::XML::Builder.new do |xml|
          xml.rpc do
            xml.send('request-pfe-execute') do
              xml.send('target', params[:target])
              if params[:command].class.to_s =~ /^Array/
                params[:command].each do |cmd|
                  xml.send('command', cmd)
                end
              elsif params[:command].class.to_s =~ /^String/
                xml.send('command', params[:command])
              end
            end
          end
        end
        @trans.rpc_exec(rpc_nx)
      end

      def rollback(n = 0)
        ArgumentError "rollback between 0 and 49 only" unless n.between?(0,49)
        reply = load_configuration(rollback: n)
        !reply.xpath('//ok').empty? # return true or false to indicate success or not
      end
    end # module: JUNOS
  end # module: RPC
end # module: Netconf
