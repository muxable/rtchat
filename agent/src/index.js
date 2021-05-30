"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var admin = require("firebase-admin");
var pubsub_1 = require("@google-cloud/pubsub");
var dotenv = require("dotenv");
var bottleneck_1 = require("bottleneck");
var process = require("process");
var uuid_1 = require("uuid");
var client_1 = require("./client");
dotenv.config();
admin.initializeApp({
    databaseURL: "https://rtchat-47692-default-rtdb.firebaseio.com"
});
var AGENT_ID = uuid_1.v4();
console.log("running agent", AGENT_ID);
var CLIENTS = [client_1.buildClient(), client_1.buildClient()];
var JOIN_BOTTLENECK = new bottleneck_1["default"]({
    maxConcurrent: 50,
    minTime: 15 * 1000
});
function subscribe(provider, channel) {
    return __awaiter(this, void 0, void 0, function () {
        var _a, err_1;
        var _this = this;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _a = provider;
                    switch (_a) {
                        case "twitch": return [3 /*break*/, 1];
                    }
                    return [3 /*break*/, 6];
                case 1:
                    if (!JOIN_BOTTLENECK.check()) return [3 /*break*/, 6];
                    _b.label = 2;
                case 2:
                    _b.trys.push([2, 4, , 5]);
                    return [4 /*yield*/, JOIN_BOTTLENECK.schedule(function () { return __awaiter(_this, void 0, void 0, function () {
                            var _i, CLIENTS_1, client;
                            return __generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        _i = 0, CLIENTS_1 = CLIENTS;
                                        _a.label = 1;
                                    case 1:
                                        if (!(_i < CLIENTS_1.length)) return [3 /*break*/, 4];
                                        client = CLIENTS_1[_i];
                                        return [4 /*yield*/, client.join(channel)];
                                    case 2:
                                        _a.sent();
                                        _a.label = 3;
                                    case 3:
                                        _i++;
                                        return [3 /*break*/, 1];
                                    case 4: return [2 /*return*/];
                                }
                            });
                        }); })];
                case 3:
                    _b.sent();
                    return [3 /*break*/, 5];
                case 4:
                    err_1 = _b.sent();
                    console.error(err_1);
                    return [2 /*return*/, false];
                case 5: return [2 /*return*/, true];
                case 6: return [2 /*return*/, false]; // not handled by this agent.
            }
        });
    });
}
function unsubscribe(provider, channel) {
    return __awaiter(this, void 0, void 0, function () {
        var _a, _i, CLIENTS_2, client, err_2;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _a = provider;
                    switch (_a) {
                        case "twitch": return [3 /*break*/, 1];
                    }
                    return [3 /*break*/, 8];
                case 1:
                    _b.trys.push([1, 6, , 7]);
                    _i = 0, CLIENTS_2 = CLIENTS;
                    _b.label = 2;
                case 2:
                    if (!(_i < CLIENTS_2.length)) return [3 /*break*/, 5];
                    client = CLIENTS_2[_i];
                    return [4 /*yield*/, client.part(channel)];
                case 3:
                    _b.sent();
                    _b.label = 4;
                case 4:
                    _i++;
                    return [3 /*break*/, 2];
                case 5: return [3 /*break*/, 7];
                case 6:
                    err_2 = _b.sent();
                    console.error(err_2);
                    return [2 /*return*/, false];
                case 7: return [2 /*return*/, true];
                case 8: return [2 /*return*/, false]; // not handled by this agent.
            }
        });
    });
}
var locks = new Set();
function onSubscribe(message) {
    return __awaiter(this, void 0, void 0, function () {
        var _a, provider, channel, key, lockRef;
        var _this = this;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _a = JSON.parse(message.data.toString()), provider = _a.provider, channel = _a.channel;
                    key = provider + ":" + channel;
                    lockRef = admin.database().ref("locks").child(provider).child(channel);
                    return [4 /*yield*/, lockRef.transaction(function (current) {
                            if (!current) {
                                return AGENT_ID;
                            }
                        }, function (error, committed) { return __awaiter(_this, void 0, void 0, function () {
                            return __generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        if (error) {
                                            console.error(error);
                                        }
                                        if (!committed) {
                                            return [2 /*return*/];
                                        }
                                        return [4 /*yield*/, subscribe(provider, channel)];
                                    case 1:
                                        if (!_a.sent()) return [3 /*break*/, 2];
                                        console.log("successful subscribe", provider, channel);
                                        message.ack();
                                        locks.add(key);
                                        return [3 /*break*/, 4];
                                    case 2:
                                        console.log("failed subscribe", provider, channel);
                                        message.nack();
                                        return [4 /*yield*/, lockRef.set(null)];
                                    case 3:
                                        _a.sent();
                                        locks["delete"](key);
                                        _a.label = 4;
                                    case 4: return [2 /*return*/];
                                }
                            });
                        }); })];
                case 1:
                    _b.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function onUnsubscribe(message) {
    return __awaiter(this, void 0, void 0, function () {
        var _a, provider, channel, key, lockRef;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _a = JSON.parse(message.data.toString()), provider = _a.provider, channel = _a.channel;
                    key = provider + ":" + channel;
                    return [4 /*yield*/, unsubscribe(provider, channel)];
                case 1:
                    if (!_b.sent()) return [3 /*break*/, 4];
                    console.log("successful unsubscribe", provider, channel);
                    message.ack();
                    if (!locks.has(key)) return [3 /*break*/, 3];
                    lockRef = admin
                        .database()
                        .ref("locks")
                        .child(provider)
                        .child(channel);
                    return [4 /*yield*/, lockRef.set(null)];
                case 2:
                    _b.sent();
                    locks["delete"](key);
                    _b.label = 3;
                case 3: return [3 /*break*/, 5];
                case 4:
                    console.log("failed unsubscribe", provider, channel);
                    message.nack();
                    _b.label = 5;
                case 5: return [2 /*return*/];
            }
        });
    });
}
var JOIN_TOPIC = new pubsub_1.PubSub().topic("projects/rtchat-47692/topics/subscribe");
var JOIN_SUBSCRIPTION = JOIN_TOPIC.subscription("projects/rtchat-47692/subscriptions/subscribe-sub");
JOIN_SUBSCRIPTION.on("message", onSubscribe);
var LEAVE_TOPIC = new pubsub_1.PubSub().topic("projects/rtchat-47692/topics/unsubscribe");
var LEAVE_SUBSCRIPTION_ID = "projects/rtchat-47692/subscriptions/unsubscribe-" + AGENT_ID;
(function () {
    return __awaiter(this, void 0, void 0, function () {
        var subscription;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, LEAVE_TOPIC.createSubscription(LEAVE_SUBSCRIPTION_ID)];
                case 1:
                    subscription = (_a.sent())[0];
                    subscription.on("message", onUnsubscribe);
                    return [2 /*return*/];
            }
        });
    });
})();
process.once("SIGTERM", function () { return __awaiter(void 0, void 0, void 0, function () {
    var _i, _a, lock, _b, provider, channel, channels, _c, CLIENTS_3, client, _d, _e, channel, _f, _g, channel, payload;
    return __generator(this, function (_h) {
        switch (_h.label) {
            case 0:
                JOIN_SUBSCRIPTION.off("message", onSubscribe);
                return [4 /*yield*/, LEAVE_TOPIC.subscription(LEAVE_SUBSCRIPTION_ID)["delete"]()];
            case 1:
                _h.sent();
                _i = 0, _a = Array.from(locks.values());
                _h.label = 2;
            case 2:
                if (!(_i < _a.length)) return [3 /*break*/, 5];
                lock = _a[_i];
                _b = lock.split(":"), provider = _b[0], channel = _b[1];
                return [4 /*yield*/, admin
                        .database()
                        .ref("locks")
                        .child(provider)
                        .child(channel)
                        .set(null)];
            case 3:
                _h.sent();
                _h.label = 4;
            case 4:
                _i++;
                return [3 /*break*/, 2];
            case 5:
                channels = new Set();
                for (_c = 0, CLIENTS_3 = CLIENTS; _c < CLIENTS_3.length; _c++) {
                    client = CLIENTS_3[_c];
                    for (_d = 0, _e = client.getChannels(); _d < _e.length; _d++) {
                        channel = _e[_d];
                        channels.add(channel);
                    }
                }
                _f = 0, _g = Array.from(channels);
                _h.label = 6;
            case 6:
                if (!(_f < _g.length)) return [3 /*break*/, 9];
                channel = _g[_f];
                payload = JSON.stringify({
                    provider: "twitch",
                    channel: channel.substring(1)
                });
                return [4 /*yield*/, JOIN_TOPIC.publish(Buffer.from(payload))];
            case 7:
                _h.sent();
                _h.label = 8;
            case 8:
                _f++;
                return [3 /*break*/, 6];
            case 9:
                process.exit(0);
                return [2 /*return*/];
        }
    });
}); });
