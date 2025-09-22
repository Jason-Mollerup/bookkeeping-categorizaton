import React, { useState } from "react";
import RuleList from "./RuleList";
import AdvancedRuleBuilder from "./AdvancedRuleBuilder";
import type { CategorizationRule } from "@/types";

const Rules: React.FC = () => {
  const [builderOpen, setBuilderOpen] = useState(false);
  const [editingRule, setEditingRule] = useState<
    CategorizationRule | undefined
  >();
  const [builderMode, setBuilderMode] = useState<"create" | "edit">("create");

  const handleAddRule = () => {
    setEditingRule(undefined);
    setBuilderMode("create");
    setBuilderOpen(true);
  };

  const handleEditRule = (rule: CategorizationRule) => {
    setEditingRule(rule);
    setBuilderMode("edit");
    setBuilderOpen(true);
  };

  return (
    <>
      <RuleList onAdd={handleAddRule} onEdit={handleEditRule} />

      <AdvancedRuleBuilder
        open={builderOpen}
        onClose={() => setBuilderOpen(false)}
        rule={editingRule}
        mode={builderMode}
      />
    </>
  );
};

export default Rules;
