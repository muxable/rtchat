package webhook

import (
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"
	"unicode/utf8"
)

type alchemyDonation struct {
	To      string
	Amount  *big.Int
	Donor   string
	Message string
}

// decodeAlchemyDonation implements the donate(address,uint256,string,string)
// ABI. The amount is decoded exactly but is not stored by the TS webhook.
func decodeAlchemyDonation(input string) (*alchemyDonation, error) {
	data, err := hex.DecodeString(strings.TrimPrefix(input, "0x"))
	if err != nil || len(data) < 4 {
		return nil, fmt.Errorf("invalid transaction calldata")
	}
	switch hex.EncodeToString(data[:4]) {
	case "12065fe0", "26b85ee1": // getBalance(), myAddress(): known, non-donation ABI calls.
		return nil, nil
	case "98701e4c": // First four bytes of keccak256(donate(address,uint256,string,string)).
	default:
		return nil, fmt.Errorf("unknown transaction selector")
	}
	args := data[4:]
	if len(args) < 128 {
		return nil, fmt.Errorf("truncated donation arguments")
	}
	for _, b := range args[:12] {
		if b != 0 {
			return nil, fmt.Errorf("invalid receiver address")
		}
	}
	donor, err := alchemyABIString(args, args[64:96])
	if err != nil {
		return nil, err
	}
	message, err := alchemyABIString(args, args[96:128])
	if err != nil {
		return nil, err
	}
	return &alchemyDonation{
		To: "0x" + hex.EncodeToString(args[12:32]), Amount: new(big.Int).SetBytes(args[32:64]),
		Donor: donor, Message: message,
	}, nil
}

func alchemyABIString(args, word []byte) (string, error) {
	offset := new(big.Int).SetBytes(word)
	if !offset.IsInt64() || offset.Int64() > int64(len(args))-32 {
		return "", fmt.Errorf("invalid ABI string offset")
	}
	start := int(offset.Int64())
	size := new(big.Int).SetBytes(args[start : start+32])
	start += 32
	if !size.IsInt64() || size.Int64() > int64(len(args)-start) {
		return "", fmt.Errorf("invalid ABI string length")
	}
	value := args[start : start+int(size.Int64())]
	if !utf8.Valid(value) {
		return "", fmt.Errorf("invalid ABI string UTF-8")
	}
	return string(value), nil
}
