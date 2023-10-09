

extension Float {
    func metersToImperialString() -> String {
        let feet = self * 3.28084
        let wholeFeet = Int(feet)
        let remainingInches = (feet - Float(wholeFeet)) * 12.0
        
        return String(format: "%d' %.1f\"", wholeFeet, remainingInches)
    }
}
