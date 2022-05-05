#ifndef SOSDB_PGM_H
#define SOSDB_PGM_H

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <vector>

#include "../util.h"
#include "base.h"
#include "pgm_index_dynamic.hpp"
//#include <functional>
//#include <boost/iterator/transform_iterator.hpp>
//#include <boost/range/adaptors.hpp>

template <class KeyType, int pgm_error>
class PGM : public Competitor {
 public:
  uint64_t Build(const std::vector<KeyValue<KeyType>>& data) {

    std::vector<std::pair<KeyType, uint64_t>> kvPairs;
    kvPairs.reserve(data.size());
    for (KeyValue<KeyType> kv : data) {
      const auto key = kv.key;
      const auto value = kv.value;
      kvPairs.push_back(std::make_pair(key, value));
    }

    uint64_t build_time =
        util::timing([&] { pgm_ = decltype(pgm_)(kvPairs.begin(), kvPairs.end()); });

    return build_time;
  }

  SearchBound EqualityLookup(const KeyType lookup_key) const {
    auto foundItem = pgm_.find(lookup_key);

    return (SearchBound){foundItem->key(), foundItem->key() + 1};
  }

  void Insert(const KeyValue<KeyType> keyValue) {
    pgm_.insert(keyValue.key, keyValue.value);
  }

  std::string name() const { return "PGM"; }

  std::size_t size() const { return pgm_.size_in_bytes(); }

  bool applicable(bool unique, const std::string& data_filename) const {
    return true;
  }

  int variant() const { return pgm_error; }

 private:
  DynamicPGMIndex<KeyType, uint64_t, PGMIndex<KeyType, pgm_error, 4>, 18> pgm_;
};

#endif  // SOSDB_PGM_H
