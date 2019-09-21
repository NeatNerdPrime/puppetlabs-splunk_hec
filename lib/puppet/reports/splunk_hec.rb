require 'puppet/util/splunk_hec'

Puppet::Reports.register_report(:splunk_hec) do
  desc 'Submits just a report summary to Splunk HEC endpoint'
  # Next, define and configure the report processor.

  include Puppet::Util::Splunk_hec
  def process
    # now we can create the event with the timestamp from the report

    epoch = sourcetypetime(time.iso8601(3))

    # pass simple metrics for report processing later
    #  STATES = [:skipped, :failed, :failed_to_restart, :restarted, :changed, :out_of_sync, :scheduled, :corrective_change]
    metrics = {
      'time' => {
        'config_retrieval' => self.metrics['time']['config_retrieval'],
        'fact_generation' => self.metrics['time']['fact_generation'],
        'catalog_application' => self.metrics['time']['catalog_application'],
        'total' => self.metrics['time']['total'],
      },
      'resources' => {
        'total' => self.metrics['resources']['total'],
      },
      'changes' => {
        'total' => self.metrics['changes']['total'],
      },
    }

    # puppet 4 compatibility, code_id and job_id were added in puppet 5
    if defined?(job_id)
      local_job_id = job_id
    else
      local_job_id = ''
    end

    if defined?(code_id)
      local_code_id = code_id
    else
      local_code_id = ''
    end

    event = {
      'host' => host,
      'time' => epoch,
      'sourcetype' => 'puppet:summary',
      'event' => {
        'cached_catalog_status' =>  cached_catalog_status,
        'catalog_uuid' => catalog_uuid,
        'certname' => host,
        'code_id' => local_code_id,
        'configuration_version' => configuration_version,
        'corrective_change' => corrective_change,
        'environment' => environment,
        'job_id' => local_job_id,
        'metrics' => metrics,
        'noop' => noop,
        'noop_pending' => noop_pending,
        'pe_console' => pe_console,
        'producer' => Puppet[:certname],
        'puppet_version' => puppet_version,
        'report_format' => report_format,
        'status' => status,
        'time' => time.iso8601(3),
        'transaction_uuid' => transaction_uuid,
      },
    }

    Puppet.info "Submitting report to Splunk at #{get_splunk_url('summary')}"
    submit_request event
    if record_event
      store_event event
    end
  rescue StandardError => e
    Puppet.err "Could not send report to Splunk: #{e}\n#{e.backtrace}"
  end
end
