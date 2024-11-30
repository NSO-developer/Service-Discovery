import ncs
from multi_service_action.action import InvokeAction

class Main(ncs.application.Application):
    def setup(self):
        self.log.info('Main RUNNING')
        self.register_action('msa-re-deploy', InvokeAction)
        self.register_action('msa-check-sync', InvokeAction)

    def teardown(self):
        self.log.info('Main FINISHED')
