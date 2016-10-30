import Foundation
#if os(macOS)
    import PostboxMac
#else
    import Postbox
#endif

public enum UserPresenceStatus: Comparable, Coding {
    case none
    case present(until: Int32)
    case recently
    case lastWeek
    case lastMonth
    
    public static func ==(lhs: UserPresenceStatus, rhs: UserPresenceStatus) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case let .present(until):
                if case .present(until) = rhs {
                    return true
                } else {
                    return false
                }
            case .recently:
                if case .recently = rhs {
                    return true
                } else {
                    return false
                }
            case .lastWeek:
                if case .lastWeek = rhs {
                    return true
                } else {
                    return false
                }
            case .lastMonth:
                if case .lastMonth = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
    
    public static func <(lhs: UserPresenceStatus, rhs: UserPresenceStatus) -> Bool {
        switch lhs {
            case .none:
                switch rhs {
                    case .none:
                        return false
                    case .lastMonth, .lastWeek, .recently, .present:
                        return true
                }
            case let .present(until):
                switch rhs {
                    case .none:
                        return false
                    case let .present(rhsUntil):
                        return until < rhsUntil
                    case .lastWeek, .lastMonth, .recently:
                        return false
                }
            case .recently:
                switch rhs {
                    case .none, .lastWeek, .lastMonth, .recently:
                        return false
                    case .present:
                        return true
                }
            case .lastWeek:
                switch rhs {
                    case .none, .lastMonth, .lastWeek:
                        return false
                    case .present, .recently:
                        return true
                }
            case .lastMonth:
                switch rhs {
                    case .none, .lastMonth:
                        return false
                    case .present, .recently, lastWeek:
                        return true
                }
        }
    }
    
    public init(decoder: Decoder) {
        switch decoder.decodeInt32ForKey("v") as Int32 {
            case 0:
                self = .none
            case 1:
                self = .present(until: decoder.decodeInt32ForKey("t"))
            case 2:
                self = .recently
            case 3:
                self = .lastWeek
            case 4:
                self = .lastMonth
            default:
                self = .none
        }
    }
    
    public func encode(_ encoder: Encoder) {
        switch self {
            case .none:
                encoder.encodeInt32(0, forKey: "v")
            case let .present(timestamp):
                encoder.encodeInt32(1, forKey: "v")
                encoder.encodeInt32(timestamp, forKey: "t")
            case .recently:
                encoder.encodeInt32(2, forKey: "v")
            case .lastWeek:
                encoder.encodeInt32(3, forKey: "v")
            case .lastMonth:
                encoder.encodeInt32(4, forKey: "v")
        }
    }
}

public final class TelegramUserPresence: PeerPresence {
    public let status: UserPresenceStatus
    
    init(status: UserPresenceStatus) {
        self.status = status
    }
    
    public init(decoder: Decoder) {
        self.status = UserPresenceStatus(decoder: decoder)
    }
    
    public func encode(_ encoder: Encoder) {
        self.status.encode(encoder)
    }
    
    public func isEqual(to: PeerPresence) -> Bool {
        if let to = to as? TelegramUserPresence, to.status == self.status {
            return true
        } else {
            return false
        }
    }
}

extension TelegramUserPresence {
    convenience init(apiStatus: Api.UserStatus) {
        switch apiStatus {
            case .userStatusEmpty:
                self.init(status: .none)
            case let .userStatusOnline(expires):
                self.init(status: .present(until: expires))
            case let .userStatusOffline(wasOnline):
                self.init(status: .present(until: wasOnline))
            case .userStatusRecently:
                self.init(status: .recently)
            case .userStatusLastWeek:
                self.init(status: .lastWeek)
            case .userStatusLastMonth:
                self.init(status: .lastMonth)
        }
    }
    
    convenience init?(apiUser: Api.User) {
        switch apiUser {
            case let .user(_, _, _, _, _, _, _, _, status, _, _, _):
                if let status = status {
                    self.init(apiStatus: status)
                } else {
                    return nil
                }
            case .userEmpty:
                return nil
        }
    }
}