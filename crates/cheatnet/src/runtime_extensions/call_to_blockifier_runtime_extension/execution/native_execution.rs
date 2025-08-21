use std::collections::HashMap;

use blockifier::{
    execution::{
        call_info::{CallExecution, CallInfo, Retdata},
        contract_class::TrackedResource,
        entry_point::{EntryPointExecutionContext, ExecutableCallEntryPoint},
        errors::{EntryPointExecutionError, PostExecutionError, PreExecutionError},
        native::{contract_class::NativeCompiledClassV1, syscall_handler::NativeSyscallHandler},
        syscalls::vm_syscall_utils::SyscallUsageMap,
    },
    state::state_api::State,
};
use cairo_native::{execution_result::ContractExecutionResult, utils::BuiltinCosts};
use runtime::native::{NativeExtendedRuntime, NativeStarknetRuntime};

use crate::{
    runtime_extensions::cheatable_starknet_runtime_extension::CheatableStarknetRuntimeExtension,
    state::CheatnetState,
};

use super::entry_point::{CallInfoWithExecutionData, ContractClassEntryPointExecutionResult};

// blockifier/src/execution/native/entry_point_execution.rs:20 (execute_entry_point_call)
#[expect(clippy::result_large_err)]
pub(crate) fn execute_entry_point_call_native(
    call: ExecutableCallEntryPoint,
    compiled_class: &NativeCompiledClassV1,
    state: &mut dyn State,
    cheatnet_state: &mut CheatnetState, // Added parameter
    context: &mut EntryPointExecutionContext,
) -> ContractClassEntryPointExecutionResult {
    let entry_point = compiled_class.get_entry_point(&call.type_and_selector())?;

    let syscall_handler: NativeSyscallHandler<'_> = NativeSyscallHandler::new(call, state, context);

    let gas_costs = syscall_handler.base.context.gas_costs();
    let builtin_costs = BuiltinCosts {
        r#const: 1,
        pedersen: gas_costs.builtins.pedersen,
        bitwise: gas_costs.builtins.bitwise,
        ecop: gas_costs.builtins.ecop,
        poseidon: gas_costs.builtins.poseidon,
        add_mod: gas_costs.builtins.add_mod,
        mul_mod: gas_costs.builtins.mul_mod,
    };

    let initial_budget = syscall_handler
        .base
        .context
        .gas_costs()
        .base
        .entry_point_initial_budget;
    let call_initial_gas = syscall_handler
        .base
        .call
        .initial_gas
        .checked_sub(initial_budget)
        .ok_or(PreExecutionError::InsufficientEntryPointGas)?;

    // region: Modified blockifier code
    let mut cheatable_runtime = NativeExtendedRuntime {
        extension: CheatableStarknetRuntimeExtension { cheatnet_state },
        runtime: NativeStarknetRuntime { syscall_handler },
    };
    let execution_result = compiled_class.executor.run(
        entry_point.selector.0,
        &cheatable_runtime
            .runtime
            .syscall_handler
            .base
            .call
            .calldata
            .0
            .clone(),
        call_initial_gas,
        Some(builtin_costs),
        &mut cheatable_runtime,
    );
    let mut syscall_handler = cheatable_runtime.runtime.syscall_handler;
    // endregion

    syscall_handler.finalize();

    let call_result = execution_result.map_err(EntryPointExecutionError::NativeUnexpectedError)?;

    if let Some(error) = syscall_handler.unrecoverable_error {
        return Err(EntryPointExecutionError::NativeUnrecoverableError(Box::new(error)).into());
    }

    let call_info_result = create_callinfo(call_result, syscall_handler);

    // region: Modified blockifier code
    Ok(CallInfoWithExecutionData {
        call_info: call_info_result?,
        syscall_usage_vm_resources: SyscallUsageMap::default(),
        syscall_usage_sierra_gas: SyscallUsageMap::default(),
        vm_trace: None,
    })
    // endregion
}

#[allow(clippy::result_large_err)]
fn create_callinfo(
    call_result: ContractExecutionResult,
    syscall_handler: NativeSyscallHandler<'_>,
) -> Result<CallInfo, EntryPointExecutionError> {
    let remaining_gas = call_result.remaining_gas;

    if remaining_gas > syscall_handler.base.call.initial_gas {
        return Err(PostExecutionError::MalformedReturnData {
            error_message: format!(
                "Unexpected remaining gas. Used gas is greater than initial gas: {} > {}",
                remaining_gas, syscall_handler.base.call.initial_gas
            ),
        }
        .into());
    }

    let gas_consumed = syscall_handler.base.call.initial_gas - remaining_gas;
    let vm_resources = CallInfo::summarize_vm_resources(syscall_handler.base.inner_calls.iter());

    Ok(CallInfo {
        call: syscall_handler.base.call.into(),
        execution: CallExecution {
            retdata: Retdata(call_result.return_values),
            events: syscall_handler.base.events,
            cairo_native: true,
            l2_to_l1_messages: syscall_handler.base.l2_to_l1_messages,
            failed: call_result.failure_flag,
            gas_consumed,
        },
        resources: vm_resources,
        inner_calls: syscall_handler.base.inner_calls,
        storage_access_tracker: syscall_handler.base.storage_access_tracker,
        tracked_resource: TrackedResource::SierraGas,
        builtin_counters: HashMap::default(),
    })
}
