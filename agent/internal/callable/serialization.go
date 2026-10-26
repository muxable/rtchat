package callable

import (
	"bytes"
	"encoding/json"
	"errors"
	"strconv"
)

// Mobile SDKs encode 64-bit integers as protobuf wrapper objects, even for
// small values such as a timeout's duration. Decode them before route structs
// unmarshal the data. UseNumber keeps ordinary JSON integers exact as well.
func decodeData(data json.RawMessage) (json.RawMessage, error) {
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.UseNumber()
	var value any
	if err := dec.Decode(&value); err != nil {
		return nil, err
	}
	value, err := decodeValue(value)
	if err != nil {
		return nil, err
	}
	return json.Marshal(value)
}

func decodeValue(value any) (any, error) {
	switch v := value.(type) {
	case map[string]any:
		kind, _ := v["@type"].(string)
		if kind == "type.googleapis.com/google.protobuf.Int64Value" || kind == "type.googleapis.com/google.protobuf.UInt64Value" {
			text, ok := v["value"].(string)
			if !ok {
				return nil, errors.New("invalid integer wrapper")
			}
			var number string
			if kind == "type.googleapis.com/google.protobuf.Int64Value" {
				n, err := strconv.ParseInt(text, 10, 64)
				if err != nil {
					return nil, err
				}
				number = strconv.FormatInt(n, 10)
			} else {
				n, err := strconv.ParseUint(text, 10, 64)
				if err != nil {
					return nil, err
				}
				number = strconv.FormatUint(n, 10)
			}
			return json.Number(number), nil
		}
		for key, child := range v {
			decoded, err := decodeValue(child)
			if err != nil {
				return nil, err
			}
			v[key] = decoded
		}
	case []any:
		for i, child := range v {
			decoded, err := decodeValue(child)
			if err != nil {
				return nil, err
			}
			v[i] = decoded
		}
	}
	return value, nil
}
