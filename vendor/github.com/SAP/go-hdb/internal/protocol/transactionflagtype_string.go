// Code generated by "stringer -type=transactionFlagType"; DO NOT EDIT.

package protocol

import "strconv"

const _transactionFlagType_name = "tfRolledbacktfCommitedtfNewIsolationLeveltfDDLCommitmodeChangedtfWriteTransactionStartedtfNowriteTransactionStartedtfSessionClosingTransactionError"

var _transactionFlagType_index = [...]uint8{0, 12, 22, 41, 63, 88, 115, 147}

func (i transactionFlagType) String() string {
	if i < 0 || i >= transactionFlagType(len(_transactionFlagType_index)-1) {
		return "transactionFlagType(" + strconv.FormatInt(int64(i), 10) + ")"
	}
	return _transactionFlagType_name[_transactionFlagType_index[i]:_transactionFlagType_index[i+1]]
}